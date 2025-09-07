
import 'package:image_picker/image_picker.dart';
import 'package:riverpod/riverpod.dart';

import '../models/contact.dart';
import '../models/contact_model.dart';



// Contact Notifier
class ContactNotifier extends StateNotifier<ContactState> {
  ContactNotifier() : super(ContactState());

  // Update person name
  void updatePersonName(String name) {
    state = state.copyWith(personName: name);
  }

  // Update company name
  void updateCompanyName(String name) {
    state = state.copyWith(companyName: name);
  }

  // Update location
  void updateLocation(String location) {
    state = state.copyWith(location: location);
  }

  // Update phone number
  void updatePhoneNumber(String number) {
    state = state.copyWith(phoneNumber: number);
  }

  // Update email
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  // Update notes
  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  // Update contact type
  void updateContactType(String type) {
    state = state.copyWith(contactType: type);
  }

  // Add images
  void addImages(List<XFile> images) {
    state = state.copyWith(contactImages: [...state.contactImages, ...images]);
  }
  // In your contact provider class
  void setContactData(Contact contact) {
    state = state.copyWith(
      personName: contact.personName,
      companyName: contact.companyName,
      location: contact.location,
      phoneNumber: contact.phoneNumber,
      email: contact.email,
      contactType: contact.contactType,
      notes: contact.notes,
      isEditing: true, // Add this flag to track edit mode
    );

  }

  // Remove image
  void removeImage(int index) {
    final newImages = List<XFile>.from(state.contactImages);
    newImages.removeAt(index);
    state = state.copyWith(contactImages: newImages);
  }

  // Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Set upload progress
  void setUploadProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  // Set upload status
  void setUploadStatus(String status) {
    state = state.copyWith(uploadStatus: status);
  }

  // Clear form
  void clearForm() {
    state = ContactState();
  }

  // In your ContactNotifier class
  void resetForNewContact() {
    state = ContactState(); // Reset to initial state
  }

  void loadContactForEditing(Contact contact) {
    state = ContactState(
      personName: contact.personName,
      companyName: contact.companyName,
      location: contact.location,
      phoneNumber: contact.phoneNumber,
      email: contact.email,
      notes: contact.notes,
      contactType: contact.contactType,
      contactImages: const [], // Keep images empty or load existing images if needed
      isLoading: false,
      uploadProgress: 0.0,
      uploadStatus: '',
    );
  }
}



// Provider for contact state
// Change your provider definition
final contactProvider = StateNotifierProvider.autoDispose<ContactNotifier, ContactState>(
      (ref) => ContactNotifier(),
);