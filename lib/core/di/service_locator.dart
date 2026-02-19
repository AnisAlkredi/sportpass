import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

import '../../features/home/domain/home_repository.dart';
import '../../features/home/data/home_repository_impl.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';

import '../../features/partners/domain/partners_repository.dart';
import '../../features/partners/data/partners_repository_impl.dart';
import '../../features/partners/presentation/cubit/partners_cubit.dart';

import '../../features/checkin/domain/checkin_repository.dart';
import '../../features/checkin/data/checkin_repository_impl.dart';
import '../../features/checkin/presentation/cubit/checkin_cubit.dart';

import '../../features/wallet/domain/wallet_repository.dart';
import '../../features/wallet/data/wallet_repository_impl.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';

import '../../features/activity/presentation/cubit/activity_cubit.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';

/// Simple service locator
final Map<Type, dynamic> _registry = {};

T sl<T>() => _registry[T] as T;

Future<void> setupServiceLocator() async {
  final sb = Supabase.instance.client;

  // Repositories
  _registry[AuthRepository] = AuthRepositoryImpl(sb);
  _registry[HomeRepository] = HomeRepositoryImpl(sb);
  _registry[PartnersRepository] = PartnersRepositoryImpl(sb);
  _registry[CheckinRepository] = CheckinRepositoryImpl(sb);
  _registry[WalletRepository] = WalletRepositoryImpl(sb);

  // Cubits
  _registry[AuthCubit] = AuthCubit(sl<AuthRepository>());
  _registry[HomeCubit] = HomeCubit(sl<HomeRepository>());
  _registry[PartnersCubit] = PartnersCubit(sl<PartnersRepository>());
  _registry[CheckinCubit] = CheckinCubit(sl<CheckinRepository>());
  _registry[WalletCubit] = WalletCubit(sl<WalletRepository>());
  _registry[ActivityCubit] = ActivityCubit();
  _registry[AdminCubit] = AdminCubit();
}
