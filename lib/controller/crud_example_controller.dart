import 'package:get/get.dart';
import '../backend/crud_example_service.dart';
import '../model/travel_user.dart';

class CrudExampleController extends GetxController with StateMixin<List<TravelUser>> {
  final CrudExampleService _service = CrudExampleService();

  // Action specific observables for CREATE, UPDATE, DELETE (discrete loaders)
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch users when controller starts
    fetchUsers();
  }

  /// 1. READ OPERATION (Fetch all users)
  Future<void> fetchUsers() async {
    try {
      // 1. Set state to Loading
      change(null, status: RxStatus.loading());

      // 2. Make the API Call
      final users = await _service.getTravelUsers();

      if (users.isEmpty) {
        // 3. Set state to Empty if list is empty
        change([], status: RxStatus.empty());
      } else {
        // 4. Set state to Success with data
        change(users, status: RxStatus.success());
      }
    } catch (e) {
      // 5. Set state to Error if anything fails
      change(null, status: RxStatus.error(e.toString()));
    }
  }

  /// 2. CREATE OPERATION (Add user)
  Future<void> addUser(TravelUser user) async {
    try {
      isCreating.value = true;

      // Make API Call
      final newUser = await _service.createTravelUser(user);

      // Append new user to current list and trigger success
      final currentUsers = state ?? [];
      final updatedList = List<TravelUser>.from(currentUsers)..add(newUser);
      change(updatedList, status: RxStatus.success());

      Get.snackbar('Success', 'User created successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create user: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isCreating.value = false;
    }
  }

  /// 3. UPDATE OPERATION (Update user)
  Future<void> updateUser(TravelUser updatedUser) async {
    try {
      isUpdating.value = true;

      final success = await _service.updateTravelUser(updatedUser);

      if (success) {
        // Find and replace the user in the current list
        final currentUsers = state ?? [];
        final updatedList = currentUsers.map((user) {
          return user.id == updatedUser.id ? updatedUser : user;
        }).toList();

        change(updatedList, status: RxStatus.success());
        Get.snackbar('Success', 'User updated successfully', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Failed', 'API rejected the update operation', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }

  /// 4. DELETE OPERATION (Delete user)
  Future<void> deleteUser(String id) async {
    try {
      isDeleting.value = true;

      final success = await _service.deleteTravelUser(id);

      if (success) {
        // Remove from current list
        final currentUsers = state ?? [];
        final updatedList = currentUsers.where((user) => user.id != id).toList();

        if (updatedList.isEmpty) {
          change([], status: RxStatus.empty());
        } else {
          change(updatedList, status: RxStatus.success());
        }
        Get.snackbar('Success', 'User deleted successfully', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Failed', 'API rejected the delete operation', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete user: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isDeleting.value = false;
    }
  }
}
