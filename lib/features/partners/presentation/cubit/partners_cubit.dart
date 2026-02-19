import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/partners_repository.dart';
import '../../domain/models/partner.dart';

abstract class PartnersState extends Equatable {
  const PartnersState();
  @override
  List<Object?> get props => [];
}

class PartnersInitial extends PartnersState {}

class PartnersLoading extends PartnersState {}

class PartnersLoaded extends PartnersState {
  final List<Partner> partners;
  const PartnersLoaded(this.partners);
  @override
  List<Object?> get props => [partners];
}

class PartnersError extends PartnersState {
  final String message;
  const PartnersError(this.message);
}

class PartnersCubit extends Cubit<PartnersState> {
  final PartnersRepository _repo;
  PartnersCubit(this._repo) : super(PartnersInitial());

  Future<void> loadPartners() async {
    emit(PartnersLoading());
    try {
      final partners = await _repo.getPartners();
      emit(PartnersLoaded(partners));
    } catch (e) {
      emit(PartnersError(e.toString()));
    }
  }
}
