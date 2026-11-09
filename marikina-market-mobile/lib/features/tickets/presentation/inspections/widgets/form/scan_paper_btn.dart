import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_evidence_grid.dart';

class ScanPaperBtn extends StatefulWidget {
  final List<XFile> photos;
  final String buttonLabel;
  final ValueChanged<XFile> onPhotoAdded;
  final ValueChanged<int> onPhotoRemoved;
  const ScanPaperBtn({
    required this.photos,
    required this.buttonLabel,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    super.key,
  });
  @override
  State<ScanPaperBtn> createState() => _ScanPaperBtnState();
}

class _ScanPaperBtnState extends State<ScanPaperBtn> {
  bool _isScanning = false;
  bool _scannerUnavailable = false;

  Future<void> _scan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    try {
      final pages = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        scannerSource: ScannerSource.camera,
        androidScannerMode: AndroidScannerMode.base,
      );
      if (pages == null || !mounted) return;
      setState(() => _scannerUnavailable = false);
      widget.onPhotoAdded(XFile(pages.first));
    } on CunningDocumentScannerException {
      if (mounted) setState(() => _scannerUnavailable = true);
    } on MissingPluginException {
      if (mounted) setState(() => _scannerUnavailable = true);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPrimaryButton(
        label: _isScanning ? 'Opening scanner' : widget.buttonLabel,
        iconData: Icons.document_scanner_outlined,
        onPressed: _scan,
        isLoading: _isScanning,
      ),
      if (_scannerUnavailable) ...[
        const SizedBox(height: AppTheme.inspectionTinyGap),
        Text(
          'The scanner is unavailable on this phone.',
          style: AppTheme.inspectionBodyStyle.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: AppTheme.inspectionTinyGap),
        AddPhotoEvidenceBtn(
          buttonLabel: 'Take a normal photo instead',
          photos: widget.photos,
          onPhotoAdded: widget.onPhotoAdded,
          onPhotoRemoved: widget.onPhotoRemoved,
          isInvalid: false,
        ),
      ] else if (widget.photos.isNotEmpty) ...[
        const SizedBox(height: AppTheme.inspectionSmallGap),
        InspectionEvidenceGrid(
          photos: widget.photos,
          onDelete: widget.onPhotoRemoved,
        ),
      ],
    ],
  );
}
