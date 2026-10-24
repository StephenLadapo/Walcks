import 'package:flutter/material.dart';

import '../models/walk_record.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Walk history backed by the walks the user actually recorded. When nothing
/// has been recorded yet, an honest empty state is shown instead.
class WalkHistoryPage extends StatefulWidget {
  const WalkHistoryPage({
    super.key,
    required this.repository,
    this.onStartWalk,
  });

  final WalkHistoryRepository repository;

  /// Optional CTA used from the empty state.
  final VoidCallback? onStartWalk;

  @override
  State<WalkHistoryPage> createState() => _WalkHistoryPageState();
}

class _WalkHistoryPageState extends State<WalkHistoryPage> {
  List<WalkRecord> _records = <WalkRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    try {
      final records = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      WalcksToast.show(
        context,
        'Could not load your walk history.',
        error: true,
      );
    }
  }

  Future<void> _delete(WalkRecord record) async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Delete this walk?',
      message:
          'The record of your walk to "${record.destination}" '
          'will be permanently removed from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final previous = List<WalkRecord>.from(_records);
    setState(
      () => _records = _records.where((item) => item.id != record.id).toList(),
    );

    try {
      await widget.repository.save(_records);
      if (!mounted) return;
      WalcksToast.show(context, 'Walk record deleted.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _records = previous);
      WalcksToast.show(
        context,
        'Could not delete the walk record.',
        error: true,
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Clear walk history?',
      message:
          'All ${_records.length} saved walk records will be permanently '
          'removed from this device.',
      confirmLabel: 'Clear all',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final previous = List<WalkRecord>.from(_records);
    setState(() => _records = <WalkRecord>[]);

    try {
      await widget.repository.clear();
      if (!mounted) return;
      WalcksToast.show(context, 'Walk history cleared.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _records = previous);
      WalcksToast.show(
        context,
        'Could not clear your walk history.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WalcksPageHeading(
          title: 'Walk History',
          subtitle: 'Every monitored walk you have completed or stopped.',
          icon: Icons.history_rounded,
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
                      _records.isEmpty
                          ? 'Saved walks'
                          : '${_records.length} saved '
                                '${_records.length == 1 ? 'walk' : 'walks'}',
                      style: WalcksText.cardTitle,
                    ),
                  ),
                  if (_records.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: WalcksColors.primary,
                      strokeWidth: 2.6,
                    ),
                  ),
                )
              else if (_records.isEmpty)
                _EmptyHistory(onStartWalk: widget.onStartWalk)
              else
                Column(
                  children: [
                    for (int i = 0; i < _records.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _WalkTile(
                        record: _records[i],
                        onDelete: () => _delete(_records[i]),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({this.onStartWalk});

  final VoidCallback? onStartWalk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: WalcksColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.route_rounded,
              color: WalcksColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No walks recorded yet',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: WalcksColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a monitored walk and it will be saved here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: WalcksColors.textSecondary),
          ),
          if (onStartWalk != null) ...[
            const SizedBox(height: 20),
            GradientCta(
              label: 'Start Monitored Walk',
              icon: Icons.directions_walk_rounded,
              onPressed: onStartWalk,
            ),
          ],
        ],
      ),
    );
  }
}

class _WalkTile extends StatelessWidget {
  const _WalkTile({required this.record, required this.onDelete});

  final WalkRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool completed = record.outcome == WalkOutcome.completed;
    final Color accent = completed ? WalcksColors.teal : WalcksColors.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WalcksColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WalcksColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.stop_circle_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      record.outcomeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                formatWalcksDateTime(record.startTime),
                style: WalcksText.small,
              ),
              IconButton(
                tooltip: 'Delete walk record',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: WalcksColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record.destination.isEmpty ? 'Unnamed walk' : record.destination,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WalcksColors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Detail(
                icon: Icons.timer_outlined,
                label: formatWalkDuration(record.duration),
              ),
              _Detail(
                icon: Icons.satellite_alt_rounded,
                label: '${record.gpsUpdates} GPS updates',
              ),
              if (record.startLabel.isNotEmpty)
                _Detail(
                  icon: Icons.my_location_rounded,
                  label: 'From ${record.startLabel}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: WalcksColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: WalcksText.small),
      ],
    );
  }
}
