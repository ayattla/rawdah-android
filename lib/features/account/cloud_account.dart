import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:rawdah/core/state/app_state.dart';
import 'package:rawdah/features/competition/data/online_service.dart';

/// حساب قوقل للوالدين: يربط حساب الجهاز المجهول بحساب قوقل فيبقى نفس المعرف،
/// ويحفظ تقدم الأطفال في السحابة ويسترجعه على أي جهاز آخر.
class CloudAccount {
  CloudAccount._();
  static final instance = CloudAccount._();

  User? get user => Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
  bool get linked => user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  String? get email {
    for (final p in user?.providerData ?? const <UserInfo>[]) {
      if (p.providerId == 'google.com') return p.email;
    }
    return null;
  }

  /// تسجيل الدخول بقوقل: يربط الحساب الحالي، وإن كان الحساب مربوطا من جهاز آخر يدخل عليه.
  Future<String?> signIn() async {
    if (!await Online.instance.ensure()) return 'تعذر الاتصال بالإنترنت';
    final provider = GoogleAuthProvider()..addScope('email');
    try {
      final cur = FirebaseAuth.instance.currentUser;
      if (cur != null && cur.isAnonymous) {
        try {
          await cur.linkWithProvider(provider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use' || e.code == 'provider-already-linked') {
            await FirebaseAuth.instance.signInWithProvider(provider);
          } else {
            rethrow;
          }
        }
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      Online.instance.uid = FirebaseAuth.instance.currentUser?.uid;
      (await SharedPreferences.getInstance()).setBool('cloud_linked', true);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' || e.code == 'canceled') return 'ألغيت تسجيل الدخول';
      if (e.code == 'operation-not-allowed') return 'تسجيل الدخول بقوقل غير مفعل في الخادم بعد';
      return 'تعذر تسجيل الدخول (${e.code})';
    } catch (_) {
      return 'تعذر تسجيل الدخول';
    }
  }

  Future<void> signOut() async {
    (await SharedPreferences.getInstance()).remove('cloud_linked');
    await FirebaseAuth.instance.signOut();
    Online.instance.uid = null;
  }

  DocumentReference<Map<String, dynamic>>? get _doc => user == null ? null : FirebaseFirestore.instance.collection('backups').doc(user!.uid);

  Future<String?> backup(AppState st) async {
    if (!linked || _doc == null) return 'سجل الدخول بقوقل أولا';
    try {
      await _doc!.set({'state': st.exportBackup(), 'updatedAt': FieldValue.serverTimestamp()});
      return null;
    } catch (_) {
      return 'تعذر الحفظ، تأكد من الاتصال';
    }
  }

  static bool _autoTried = false;

  /// حفظ تلقائي مرة كل يوم تقريبا عند فتح التطبيق، فقط إذا ربط ولي الأمر حساب قوقل.
  Future<void> autoBackup(AppState st) async {
    if (_autoTried) return;
    _autoTried = true;
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool('cloud_linked') ?? false)) return;
      final last = p.getInt('cloud_last') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < const Duration(hours: 20).inMilliseconds) return;
      if (!await Online.instance.ensure() || !linked) return;
      if (await backup(st) == null) await p.setInt('cloud_last', now);
    } catch (_) {}
  }

  Future<String> restore(AppState st) async {
    if (!linked || _doc == null) return 'سجل الدخول بقوقل أولا';
    try {
      final snap = await _doc!.get();
      final raw = snap.data()?['state'] as String?;
      if (raw == null) return 'ما فيه نسخة محفوظة لهذا الحساب';
      final n = st.importBackup(raw);
      return 'استرجعنا تقدم $n ${n == 1 ? 'طفل' : 'أطفال'}';
    } catch (_) {
      return 'تعذر الاسترجاع، تأكد من الاتصال';
    }
  }
}
