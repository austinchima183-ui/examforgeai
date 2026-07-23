import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../domain/repositories/offline_repository.dart';


/// Parameters for [RegisterDeviceUseCase].
class RegisterDeviceParams extends Equatable {
  const RegisterDeviceParams({required this.device});

  final DeviceRegistration device;

  @override
  List<Object?> get props => [device];
}

/// Use case: register a device for push notifications.
class RegisterDeviceUseCase {
  RegisterDeviceUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<DeviceRegistration>> call(
    RegisterDeviceParams params,
  ) async {
    if (params.device.userId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'User ID cannot be empty'),
      );
    }
    if (params.device.deviceToken.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Device token cannot be empty'),
      );
    }
    if (params.device.platform.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Platform cannot be empty'),
      );
    }

    return _repository.registerDevice(params.device);
  }
}
