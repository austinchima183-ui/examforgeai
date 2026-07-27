import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class UpdatePresenceParams extends Equatable {
  const UpdatePresenceParams({required this.isOnline});

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}

class UpdatePresenceUseCase {
  UpdatePresenceUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(UpdatePresenceParams params) async {
    return _repository.updatePresence(isOnline: params.isOnline);
  }
}
