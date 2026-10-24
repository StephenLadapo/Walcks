import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../models/app_settings.dart';
import '../models/emergency_contact.dart';
import '../models/walk_record.dart';
import '../services/sms_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// Monitored walk workflow with location tracking, destination lookup,
/// SIM selection, SMS notifications, and saved walk history.
class JourneyPage extends StatefulWidget {
  const JourneyPage({
    super.key,
    required this.contacts,
    required this.historyRepository,
    required this.settingsRepository,
    this.initialDestination,
  });

  final List<EmergencyContact> contacts;
  final WalkHistoryRepository historyRepository;
  final SettingsRepository settingsRepository;
  final String? initialDestination;

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  final TextEditingController currentLocationController =
      TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  Position? currentPosition;
  Location? destinationPosition;

  bool loadingLocation = true;
  bool journeyStarted = false;
  int? selectedSubscriptionId;
  bool trackingActive = false;
  bool sendingMessage = false;

  AppSettings _settings = AppSettings();
  DateTime? _walkStart;
  String? _alertStatus;

  StreamSubscription<Position>? _positionSubscription;
  // Prolonged-stop detection: 5-minute threshold.
  static const Duration _stopThreshold = Duration(minutes: 5);
  static const double _movementThresholdMetres = 20;
  static const double _maximumUsefulGpsAccuracyMetres = 50;

  Timer? _stopDetectionTimer;
  Position? _lastMovementPosition;

  bool _stopWarningShown = false;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  final List<Position> journeyLocations = [];

  int locationUpdateCount = 0;
  String? _selectedDestinationText;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialDestination?.trim();
    if (initial != null && initial.isNotEmpty) {
      destinationController.text = initial;
    }

    _loadSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _resetStopDetection();
    currentLocationController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await widget.settingsRepository.load();
      if (!mounted) return;
      setState(() => _settings = settings);
    } catch (_) {
      // Keep default settings if loading fails.
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => loadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => loadingLocation = false);
        _showMessage('Please turn on Location Services.', error: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => loadingLocation = false);
        _showMessage('Location permission is required.', error: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        currentLocationController.text = _formatPosition(position);
        loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loadingLocation = false);

      _showMessage(
        'Could not get your current location. '
        'Check your location settings.',
        error: true,
      );

      debugPrint('Location error: $e');
    }
  }

  String _formatPosition(Position position) =>
      '${position.latitude.toStringAsFixed(6)}, '
      '${position.longitude.toStringAsFixed(6)}';

  Future<void> _selectDestination() async {
    final destination = destinationController.text.trim();

    if (destination.isEmpty) {
      _showMessage('Please type your destination first.', error: true);
      return;
    }

    if (kIsWeb) {
      _showMessage(
        'Destination lookup may not be supported by the current '
        'geocoding plugin on web. Please test this feature on Android.',
      );
      return;
    }

    try {
      // Keep the declaration inside the try block and use the
      // returned list within that same block.
      final List<geo.Location> locations = await geo.Geocoding()
          .locationFromAddress(destination);
      if (!mounted) return;

      if (locations.isEmpty) {
        _showMessage(
          'No location was found for that destination.',
          error: true,
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: WalcksColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: WalcksColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Text('Select Destination', style: WalcksText.sectionTitle),
                  const SizedBox(height: 8),
                  Text('Results for: $destination', style: WalcksText.small),
                  const SizedBox(height: 12),
                  ...locations.take(5).map((location) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: walcksPrimaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(destination),
                      subtitle: Text(
                        'GPS: '
                        '${location.latitude.toStringAsFixed(6)}, '
                        '${location.longitude.toStringAsFixed(6)}',
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        setState(() {
                          destinationPosition = location as Location?;
                          _selectedDestinationText = destination;
                        });

                        _showMessage('Destination selected.');
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    } on PlatformException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Destination lookup failed: ${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not find that destination. '
        'Try adding the suburb, city or town.',
        error: true,
      );

      debugPrint('Destination lookup error: $e');
    }
  }

  void _startLocationTracking() {
    if (trackingActive) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;

            setState(() {
              journeyLocations.add(position);
              locationUpdateCount++;
              currentPosition = position;
              currentLocationController.text = _formatPosition(position);
            });
            _checkForProlongedStop(position);

            if (_mapReady) {
              _mapController.move(
                latlong.LatLng(position.latitude, position.longitude),
                16,
              );
            }
          },
          onError: (Object error) {
            debugPrint('Location tracking error: $error');
            _showMessage(
              'Location tracking encountered an error.',
              error: true,
            );
          },
        );

    setState(() => trackingActive = true);
  }

  void _checkForProlongedStop(Position position) {
    // Do not infer that the user has stopped if GPS accuracy is poor.
    if (position.accuracy > _maximumUsefulGpsAccuracyMetres) {
      _stopDetectionTimer?.cancel();
      _stopDetectionTimer = null;

      _lastMovementPosition = null;
      return;
    }

    if (!journeyStarted) return;

    final previous = _lastMovementPosition;

    if (previous == null) {
      _lastMovementPosition = position;

      _scheduleStopWarning();
      return;
    }

    final distanceMoved = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    // Movement of more than 20 metres restarts the 5-minute timer.
    if (distanceMoved >= _movementThresholdMetres) {
      _stopDetectionTimer?.cancel();
      _stopDetectionTimer = null;

      _lastMovementPosition = position;

      _stopWarningShown = false;

      _scheduleStopWarning();
    }
  }

  void _scheduleStopWarning() {
    _stopDetectionTimer?.cancel();

    _stopDetectionTimer = Timer(_stopThreshold, () {
      if (!mounted || !journeyStarted || _stopWarningShown) return;

      _stopWarningShown = true;
      _showProlongedStopWarning();
    });
  }

  Future<void> _showProlongedStopWarning() async {
    if (!mounted || !journeyStarted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Are you safe?'),
          content: const Text(
            'WALCKS has detected little or no movement for '
            '5 minutes. If you are taking a break and are safe, '
            'confirm below. If you need help, contact emergency '
            'services or your emergency contacts.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("I'm safe"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (journeyStarted) {
      _stopDetectionTimer?.cancel();

      setState(() {
        _lastMovementPosition = currentPosition;

        _stopWarningShown = false;
      });

      // Start another monitoring period after the warning is dismissed.
      if (currentPosition != null) {
        _scheduleStopWarning();
      }
    }
  }

  void _resetStopDetection() {
    _stopDetectionTimer?.cancel();
    _stopDetectionTimer = null;
    _lastMovementPosition = null;

    _stopWarningShown = false;
  }

  Future<int?> _chooseSmsSim() async {
    try {
      final List<Map<String, dynamic>> simOptions = await SmsService.getSims();
      final validSimOptions = simOptions.where((sim) {
        return sim['subscriptionId'] is num;
      }).toList();

      if (!mounted) return null;

      if (validSimOptions.isEmpty) {
        _showMessage(
          'No active SIM cards were found, so no emergency SMS was sent.',
          error: true,
        );
        return null;
      }

      final selectedId = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          int? selectedSimId = (validSimOptions.first['subscriptionId'] as num)
              .toInt();

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text('Choose SMS SIM'),
                content: DropdownButtonFormField<int>(
                  initialValue: selectedSimId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'SIM card'),
                  items: validSimOptions.map((sim) {
                    final id = (sim['subscriptionId'] as num).toInt();
                    final slot =
                        ((sim['simSlotIndex'] as num?)?.toInt() ?? 0) + 1;
                    final carrier = sim['displayName']?.toString() ?? '';

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        'SIM $slot'
                        '${carrier.isNotEmpty ? ' - $carrier' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSimId = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Skip'),
                  ),
                  FilledButton(
                    onPressed: selectedSimId == null
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop(selectedSimId);
                          },
                    child: const Text('Use this SIM'),
                  ),
                ],
              );
            },
          );
        },
      );

      return selectedId;
    } on PlatformException catch (e) {
      if (mounted) {
        _showMessage(
          e.code == 'PHONE_PERMISSION_DENIED'
              ? 'Phone permission is needed to send an emergency SMS.'
              : 'Could not prepare an emergency SMS: '
                    '${e.message ?? e.code}',
          error: true,
        );
      }
      return null;
    } on MissingPluginException {
      if (mounted) {
        _showMessage('SMS is not available on this platform.', error: true);
      }
      return null;
    } catch (e) {
      if (mounted) {
        _showMessage(
          'An error occurred while preparing the emergency SMS.',
          error: true,
        );
      }
      debugPrint('SIM selection error: $e');
      return null;
    }
  }

  Future<String> _sendSmsToContacts(String message) async {
    int sent = 0;
    final List<String> failed = <String>[];

    for (final contact in widget.contacts) {
      try {
        await SmsService.sendSms(
          phone: contact.phone,
          message: message,
          subscriptionId: selectedSubscriptionId,
        );
        sent++;
      } on MissingPluginException {
        return 'No emergency SMS was sent: automatic SMS is not '
            'available on this platform.';
      } on PlatformException catch (error) {
        failed.add(contact.name);
        debugPrint('SMS to ${contact.name} failed: ${error.code}');
      } catch (error) {
        failed.add(contact.name);
        debugPrint('SMS to ${contact.name} failed: $error');
      }
    }

    final buffer = StringBuffer(
      '$sent of ${widget.contacts.length} messages were handed '
      'to the device SMS service.',
    );

    if (failed.isNotEmpty) {
      buffer.write(' Could not send to ${failed.join(', ')}.');
    }

    buffer.write(' Final delivery depends on your network and carrier.');

    return buffer.toString();
  }

  String _buildStartMessage() {
    final from = currentLocationController.text.trim();
    final to = destinationController.text.trim();

    return _settings.alertMessageTemplate
        .replaceAll('{from}', from.isEmpty ? 'my current position' : from)
        .replaceAll('{to}', to.isEmpty ? 'my destination' : to);
  }

  Future<void> _startJourney() async {
    if (destinationPosition == null ||
        _selectedDestinationText != destinationController.text.trim()) {
      _showMessage(
        'Please select your destination using the Select Destination button.',
        error: true,
      );
      return;
    }

    if (currentPosition == null) {
      _showMessage(
        'Your current GPS location is unavailable. Refresh your location first.',
        error: true,
      );
      return;
    }

    if (widget.contacts.isEmpty) {
      _showMessage('Please add an emergency contact first.', error: true);
      return;
    }

    if (sendingMessage || journeyStarted) return;

    // Ask the user to choose an active SIM before sending the start alert.
    final int? chosenSubscriptionId = await _chooseSmsSim();

    if (!mounted) return;

    String alertStatus;

    if (chosenSubscriptionId == null) {
      alertStatus =
          'No start SMS was sent because no SIM was selected or '
          'SIM selection was unavailable. Your walk can still be monitored.';
    } else {
      selectedSubscriptionId = chosenSubscriptionId;

      setState(() => sendingMessage = true);

      try {
        alertStatus = await _sendSmsToContacts(_buildStartMessage());
      } catch (e) {
        debugPrint('Journey-start SMS error: $e');
        alertStatus =
            'The start SMS could not be sent. Check SMS permissions '
            'and your SIM connection.';
      } finally {
        if (mounted) {
          setState(() => sendingMessage = false);
        }
      }

      if (!mounted) return;
    }
    _resetStopDetection();

    setState(() {
      journeyStarted = true;
      _walkStart = DateTime.now();
      _alertStatus = alertStatus;
    });

    setState(() {
      journeyStarted = true;
      _walkStart = DateTime.now();
      _alertStatus = alertStatus;
    });

    _startLocationTracking();

    _showMessage(
      chosenSubscriptionId == null
          ? 'Walk monitoring started, but no SMS was sent.'
          : 'Walk monitoring started. Check the alert status for SMS results.',
      error: chosenSubscriptionId == null,
    );
  }

  Future<void> _arrive() async {
    if (sendingMessage) return;

    String? note;

    if (widget.contacts.isEmpty) {
      note = 'No emergency contacts are saved, so nobody was notified.';
    } else if (_settings.notifyContactsOnStart) {
      setState(() => sendingMessage = true);

      try {
        note = await _sendSmsToContacts(
          'I have safely arrived at '
          '${destinationController.text.trim()}.',
        );
      } catch (e) {
        debugPrint('Arrival SMS error: $e');
        note = 'The arrival SMS could not be sent.';
      } finally {
        if (mounted) {
          setState(() => sendingMessage = false);
        }
      }
    } else {
      note =
          'Contact notifications are turned off in Settings, '
          'so nobody was notified.';
    }

    if (!mounted) return;

    await _finishWalk(WalkOutcome.completed, deliveryNote: note);
  }

  Future<void> _stopJourney() => _finishWalk(WalkOutcome.stopped);

  Future<void> _finishWalk(WalkOutcome outcome, {String? deliveryNote}) async {
    final DateTime? start = _walkStart;
    final String destination = destinationController.text.trim();

    final String startLabel = journeyLocations.isNotEmpty
        ? _formatPosition(journeyLocations.first)
        : (currentPosition != null ? _formatPosition(currentPosition!) : '');

    final String endLabel = currentPosition != null
        ? _formatPosition(currentPosition!)
        : '';

    final int updates = locationUpdateCount;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _resetStopDetection();

    bool saved = false;

    if (start != null) {
      try {
        await widget.historyRepository.add(
          WalkRecord(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            startTime: start,
            endTime: DateTime.now(),
            destination: destination,
            startLabel: startLabel,
            endLabel: endLabel,
            gpsUpdates: updates,
            outcome: outcome,
          ),
        );
        saved = true;
      } catch (e) {
        debugPrint('Saving walk history failed: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      trackingActive = false;
      journeyStarted = false;
      journeyLocations.clear();
      locationUpdateCount = 0;
      _walkStart = null;
      _alertStatus = null;
    });

    final base = saved
        ? 'Walk saved to your history.'
        : 'Walk ended, but it could not be saved to your history.';

    _showMessage(
      deliveryNote == null ? base : '$base $deliveryNote',
      error: !saved,
    );
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    WalcksToast.show(context, message, error: error);
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: walcksPrimaryGradient),
        child: Column(
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              size: 44,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Plan Your Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share your route and stay monitored',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WalcksColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: WalcksColors.teal),
          const SizedBox(width: 8),
          Text(
            'Active',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: WalcksColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    final position = currentPosition;

    final center = position != null
        ? latlong.LatLng(position.latitude, position.longitude)
        : const latlong.LatLng(-26.2041, 28.0473);

    final routePoints = journeyLocations
        .map((point) => latlong.LatLng(point.latitude, point.longitude))
        .toList();

    if (position != null &&
        (routePoints.isEmpty ||
            routePoints.last.latitude != position.latitude ||
            routePoints.last.longitude != position.longitude)) {
      routePoints.add(center);
    }

    final markers = <Marker>[];

    if (position != null) {
      markers.add(
        Marker(
          point: center,
          width: 48,
          height: 48,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 34),
        ),
      );
    }

    final destination = destinationPosition;
    if (destination != null) {
      markers.add(
        Marker(
          point: latlong.LatLng(destination.latitude, destination.longitude),
          width: 48,
          height: 48,
          child: const Icon(Icons.location_on, color: Colors.red, size: 38),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Map', style: WalcksText.sectionTitle),
        const SizedBox(height: 8),
        Text(
          journeyStarted
              ? 'Your location updates as GPS positions arrive.'
              : 'Your current position and selected destination.',
          style: WalcksText.small,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 300,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onMapReady: () {
                  _mapReady = true;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safety_app',
                ),
                if (routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          position == null
              ? 'Waiting for GPS location…'
              : 'Current GPS: ${_formatPosition(position)}',
          style: WalcksText.small,
        ),
      ],
    );
  }

  Widget _buildActiveCard() {
    final DateTime? start = _walkStart;

    return WalcksSurface(
      padding: const EdgeInsets.all(22),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 66,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [WalcksColors.teal, const Color(0xFF4DC5B4)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              currentPosition == null
                  ? 'Your walk is active'
                  : 'Your walk is being monitored',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WalcksColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: _statusChip()),
          const SizedBox(height: 18),
          _infoRow(
            Icons.flag_rounded,
            'Destination',
            destinationController.text.trim(),
          ),
          if (start != null) ...[
            const SizedBox(height: 10),
            _infoRow(
              Icons.schedule_rounded,
              'Started',
              formatWalcksDateTime(start),
            ),
          ],
          const SizedBox(height: 10),
          _infoRow(
            Icons.satellite_alt_rounded,
            'GPS updates',
            '$locationUpdateCount',
          ),
          if (_alertStatus != null) ...[
            const SizedBox(height: 16),
            WalcksNotice(
              message: _alertStatus!,
              icon: Icons.notifications_active_outlined,
            ),
          ],

          if (currentPosition == null) ...[
            const SizedBox(height: 16),
            WalcksNotice(
              message:
                  'Limited monitoring: no GPS position is available. '
                  'Your location is not currently being tracked.',
              icon: Icons.location_disabled_rounded,
              accent: WalcksColors.coral,
            ),
          ],
          const SizedBox(height: 16),
          const WalcksNotice(
            message:
                'Your live map updates on this device when GPS positions '
                'are received. Your location is not automatically shared '
                'live with emergency contacts.',
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 20),
          GradientCta(
            label: sendingMessage ? 'Please wait...' : 'I Have Safely Arrived',
            icon: Icons.check_circle_rounded,
            onPressed: sendingMessage ? null : _arrive,
            expand: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: sendingMessage ? null : _stopJourney,
              icon: const Icon(Icons.stop_circle_rounded),
              label: const Text('Stop and Save Walk'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WalcksColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: WalcksColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: WalcksColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WalcksColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WalcksColors.background,
      appBar: AppBar(title: const Text('Monitored Walk')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 24),
                TextField(
                  controller: currentLocationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Point A - Current location',
                    prefixIcon: const Icon(Icons.my_location_rounded),
                    suffixIcon: loadingLocation
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: WalcksColors.primary,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh location',
                            onPressed: _getCurrentLocation,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: destinationController,
                  onChanged: (_) {
                    setState(() {
                      destinationPosition = null;
                      _selectedDestinationText = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Point B - Destination',
                    hintText: 'Type your destination',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _selectDestination,
                  icon: const Icon(Icons.place_rounded),
                  label: const Text('Select Destination'),
                ),
                if (destinationPosition != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WalcksColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: WalcksColors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Selected GPS: '
                            '${destinationPosition!.latitude.toStringAsFixed(6)}, '
                            '${destinationPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: WalcksColors.textMain,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildLiveMap(),
                const SizedBox(height: 24),
                if (journeyStarted)
                  _buildActiveCard()
                else
                  GradientCta(
                    label: sendingMessage
                        ? 'Please wait...'
                        : 'Start Monitored Walk',
                    icon: Icons.play_arrow_rounded,
                    onPressed: sendingMessage ? null : _startJourney,
                    expand: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
