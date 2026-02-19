import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/checkin_repository.dart';

abstract class CheckinState extends Equatable {
  const CheckinState();
  @override
  List<Object?> get props => [];
}

class CheckinInitial extends CheckinState {}

class CheckinScanning extends CheckinState {}

class CheckinProcessing extends CheckinState {}

class CheckinSuccess extends CheckinState {
  final Map<String, dynamic> result;
  const CheckinSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class CheckinError extends CheckinState {
  final String message;
  const CheckinError(this.message);
  @override
  List<Object?> get props => [message];
}

class CheckinCubit extends Cubit<CheckinState> {
  final CheckinRepository _repo;
  CheckinCubit(this._repo) : super(CheckinInitial());

  Future<void> processQr(String qrData) async {
    emit(CheckinProcessing());
    try {
      // Get location permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          emit(const CheckinError('يجب تفعيل خدمة الموقع'));
          return;
        }
      }

      // precise location
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Extract location ID
      final locationId = _extractToken(qrData);

      final result =
          await _repo.performCheckin(locationId, pos.latitude, pos.longitude);

      if (result['success'] == true) {
        emit(CheckinSuccess(result));
      } else {
        final msg = result['message']?.toString() ?? 'فشل تسجيل الدخول';
        emit(CheckinError(msg));
      }
    } catch (e) {
      emit(CheckinError('خطأ: $e'));
    }
  }

  String _extractToken(String data) {
    if (data.contains('token=')) {
      final uri = Uri.tryParse(data);
      return uri?.queryParameters['token'] ?? data;
    }
    // Handle UUID format coming as raw text or part of URL path
    // For now, assume raw UUID or the content is the ID
    return data.trim();
  }

  void reset() => emit(CheckinInitial());
}
