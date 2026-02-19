import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/home_repository.dart';

// States
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomeLoaded extends HomeState {
  final int todayCheckins;

  const HomeLoaded({this.todayCheckins = 0});

  bool get hasCheckedInToday => todayCheckins > 0;

  @override
  List<Object?> get props => [todayCheckins];
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;
  HomeCubit(this._repo) : super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const HomeError('No user'));
        return;
      }

      final count = await _repo.getTodayCheckinCount(userId);

      emit(HomeLoaded(todayCheckins: count));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
