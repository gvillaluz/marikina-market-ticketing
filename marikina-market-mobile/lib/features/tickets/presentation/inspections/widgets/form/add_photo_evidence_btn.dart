import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_evidence_grid.dart';

class AddPhotoEvidenceBtn extends StatefulWidget {
  final List<XFile> photos;
  final ValueChanged<XFile> onPhotoAdded;
  final ValueChanged<int> onPhotoRemoved;
  final bool isInvalid;
  const AddPhotoEvidenceBtn({
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    required this.isInvalid,
    super.key,
  });
  @override
  State<AddPhotoEvidenceBtn> createState() => _AddPhotoEvidenceBtnState();
}

class _AddPhotoEvidenceBtnState extends State<AddPhotoEvidenceBtn> {
  bool _isCapturing = false;
  String? _captureError;
  Future<void> _captureEvidence() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    try {
      final photo = await ImagePickerUtil.pickImage(
        context: context,
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (mounted && photo != null) widget.onPhotoAdded(photo);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _captureError = 'Unable to open the camera. Please try again.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _captureError = 'Camera capture is unavailable on this device.',
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppPrimaryButton(
        label: _isCapturing ? 'Opening camera' : 'Take a photo',
        iconData: Icons.add_a_photo_outlined,
        onPressed: _captureEvidence,
        isLoading: _isCapturing,
      ),
      if (_captureError != null) ...[
        const SizedBox(height: AppTheme.inspectionTinyGap),
        Text(
          _captureError!,
          style: AppTheme.inspectionBodyStyle.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
      if (widget.photos.isNotEmpty) ...[
        const SizedBox(height: AppTheme.inspectionSmallGap),
        InspectionEvidenceGrid(
          photos: widget.photos,
          onDelete: widget.onPhotoRemoved,
        ),
      ],
    ],
  );
}
