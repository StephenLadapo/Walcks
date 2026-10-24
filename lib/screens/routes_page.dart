import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/walk_record.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Routes view built on the location features Walcks actually supports:
/// the device's real GPS fix plus the destinations of previous walks.
/// No turn-by-turn map provider is configured, so none is shown.
class RoutesPage extends StatefulWidget {
  const RoutesPage({
    super.key,
    required this.historyRepository,
    this.onStartWalk,
  });

  final WalkHistoryRepository historyRepository;

  /// Called with a destination (or null for a blank walk) to start monitoring.
  final ValueChanged<String?>? onStartWalk;

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  Position? _position;
  bool _loadingLocation = true;
  String? _locationError;

  List<_RecentDestination> _recent = <_RecentDestination>[];
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadRecent();
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _locationError = null;
      });
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError = 'Location services are turned off on this device.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError =
              'Location permission was denied, so your position '
              'cannot be shown.';
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError = 'Your location could not be determined right now.';
      });
    }
  }

  Future<void> _loadRecent() async {
    try {
      final records = await widget.historyRepository.load();
      final Map<String, _RecentDestination> unique =
          <String, _RecentDestination>{};
      for (final record in records) {
        final String key = record.destination.trim().toLowerCase();
        if (key.isEmpty) continue;
        unique.putIfAbsent(
          key,
          () => _RecentDestination(record.destination.trim(), record.startTime),
        );
        if (unique.length >= 5) break;
      }
      if (!mounted) return;
      setState(() {
        _recent = unique.values.toList();
        _loadingRecent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WalcksPageHeading(
          title: 'Routes',
          subtitle: 'Your live position and the destinations you walk most.',
          icon: Icons.place_rounded,
        ),
        const SizedBox(height: 22),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your current location',
                      style: WalcksText.cardTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh location',
                    onPressed: _loadingLocation ? null : _loadLocation,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingLocation)
                SizedBox(
                  height: 64,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: WalcksColors.primary,
                      strokeWidth: 2.6,
                    ),
                  ),
                )
              else if (_locationError != null)
                WalcksNotice(
                  message: _locationError!,
                  icon: Icons.location_disabled_rounded,
                  accent: WalcksColors.coral,
                )
              else if (_position != null) ...[
                _LocationRow(
                  icon: Icons.my_location_rounded,
                  label: 'Latitude',
                  value: _position!.latitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 10),
                _LocationRow(
                  icon: Icons.explore_outlined,
                  label: 'Longitude',
                  value: _position!.longitude.toStringAsFixed(6),
                ),
                const SizedBox(height: 10),
                _LocationRow(
                  icon: Icons.gps_fixed_rounded,
                  label: 'Accuracy',
                  value: '${_position!.accuracy.toStringAsFixed(0)} m',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const WalcksNotice(
          message:
              'Walcks does not include a turn-by-turn map provider, so no '
              'map is drawn here and no route is shown as "safe". During a '
              'monitored walk your live GPS position is tracked on the device '
              'and shared with your emergency contacts through alerts.',
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Recent destinations', style: WalcksText.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Taken from the walks you have actually recorded.',
                style: WalcksText.small,
              ),
              const SizedBox(height: 16),
              if (_loadingRecent)
                SizedBox(
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: WalcksColors.primary,
                      strokeWidth: 2.6,
                    ),
                  ),
                )
              else if (_recent.isEmpty)
                Text(
                  'No destinations yet. Complete a monitored walk and its '
                  'destination will appear here.',
                  style: WalcksText.body,
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < _recent.length; i++) ...[
                      if (i > 0) const Divider(height: 24),
                      _RecentRow(
                        destination: _recent[i],
                        onWalkAgain: widget.onStartWalk == null
                            ? null
                            : () => widget.onStartWalk!(_recent[i].destination),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        if (widget.onStartWalk != null) ...[
          const SizedBox(height: 18),
          GradientCta(
            label: 'Start Monitored Walk',
            icon: Icons.directions_walk_rounded,
            onPressed: () => widget.onStartWalk!(null),
            expand: true,
          ),
        ],
      ],
    );
  }
}

class _RecentDestination {
  const _RecentDestination(this.destination, this.lastWalked);

  final String destination;
  final DateTime lastWalked;
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: TextStyle(
              color: WalcksColors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.destination, this.onWalkAgain});

  final _RecentDestination destination;
  final VoidCallback? onWalkAgain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WalcksColors.blueSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.place_rounded, color: WalcksColors.blue, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: WalcksColors.textMain,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Last walked ${formatWalcksDateTime(destination.lastWalked)}',
                style: WalcksText.small,
              ),
            ],
          ),
        ),
        if (onWalkAgain != null) ...[
          const SizedBox(width: 10),
          TextButton(onPressed: onWalkAgain, child: const Text('Walk again')),
        ],
      ],
    );
  }
}
