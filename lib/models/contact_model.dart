// State class for contact information
import 'package:image_picker/image_picker.dart';

class ContactState {
  final List<XFile> contactImages;
  final String personName;
  final String companyName;
  final String location;
  final String phoneNumber;
  final String email;
  final String notes;
  final String contactType;
  final bool isLoading;
  final double uploadProgress;
  final String uploadStatus;

  ContactState({
    this.contactImages = const [],
    this.personName = '',
    this.companyName = '',
    this.location = '',
    this.phoneNumber = '',
    this.email = '',
    this.notes = '',
    this.contactType = 'Business',
    this.isLoading = false,
    this.uploadProgress = 0.0,
    this.uploadStatus = '',
  });

  ContactState copyWith({
    List<XFile>? contactImages,
    String? personName,
    String? companyName,
    String? location,
    String? phoneNumber,
    String? email,
    String? notes,
    String? contactType,
    bool? isLoading,
    double? uploadProgress,
    String? uploadStatus,
  }) {
    return ContactState(
      contactImages: contactImages ?? this.contactImages,
      personName: personName ?? this.personName,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      contactType: contactType ?? this.contactType,
      isLoading: isLoading ?? this.isLoading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }
}