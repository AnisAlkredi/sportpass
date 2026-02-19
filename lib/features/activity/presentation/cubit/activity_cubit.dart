import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<Map<String, dynamic>> checkins;
  const ActivityLoaded(this.checkins);
  @override
  List<Object?> get props => [checkins];
}

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit() : super(ActivityInitial());

  Future<void> loadActivity() async {
    emit(ActivityLoading());
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        emit(const ActivityLoaded([]));
        return;
      }
      final r = await Supabase.instance.client
          .from('checkins')
          .select('*, partner_locations(name)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      emit(ActivityLoaded(List<Map<String, dynamic>>.from(r)));
    } catch (_) {
      emit(const ActivityLoaded([]));
    }
  }
}
