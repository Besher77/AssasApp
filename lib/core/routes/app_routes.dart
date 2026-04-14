import 'package:get/get.dart';

import '../../features/admin/controllers/admin_bank_verifications_controller.dart';
import '../../features/admin/controllers/admin_home_controller.dart';
import '../../features/admin/controllers/admin_withdrawals_controller.dart';
import '../../features/admin/controllers/admin_user_edit_controller.dart';
import '../../features/admin/controllers/admin_project_edit_controller.dart';
import '../../features/admin/controllers/admin_project_support_chat_controller.dart';
import '../../features/admin/controllers/admin_projects_controller.dart';
import '../../features/admin/controllers/admin_users_controller.dart';
import '../../features/admin/controllers/admin_wallets_controller.dart';
import '../../features/admin/views/admin_bank_verifications_view.dart';
import '../../features/admin/views/admin_home_view.dart';
import '../../features/admin/views/admin_user_edit_view.dart';
import '../../features/admin/views/admin_project_edit_view.dart';
import '../../features/admin/views/admin_project_support_chat_view.dart';
import '../../features/admin/views/admin_projects_view.dart';
import '../../features/admin/views/admin_users_view.dart';
import '../../features/admin/views/admin_wallets_view.dart';
import '../../features/admin/views/admin_withdrawals_view.dart';
import '../../features/auth/controllers/complete_profile_controller.dart';
import '../../features/auth/controllers/login_controller.dart';
import '../../features/auth/controllers/otp_controller.dart';
import '../../features/auth/controllers/signup_controller.dart';
import '../../features/auth/views/complete_profile_view.dart';
import '../../features/auth/views/engineer_registration_gate_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/otp_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/home/controllers/browse_engineers_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/views/home_view.dart';
import '../../features/projects/controllers/browse_projects_controller.dart';
import '../../features/projects/controllers/create_project_controller.dart';
import '../../features/projects/controllers/invite_engineer_project_controller.dart';
import '../../features/projects/controllers/my_projects_controller.dart';
import '../../features/projects/controllers/accept_offer_payment_controller.dart';
import '../../features/projects/controllers/submit_offer_controller.dart';
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/chat/controllers/chats_list_controller.dart';
import '../../features/chat/views/chat_landing_view.dart';
import '../../features/chat/views/chats_list_view.dart';
import '../../features/chat/views/chat_view.dart';
import '../../features/projects/views/accept_offer_payment_view.dart';
import '../../features/projects/views/card_payment_view.dart';
import '../../features/projects/views/create_project_view.dart';
import '../../features/projects/views/invite_engineer_project_view.dart';
import '../../features/projects/views/project_detail_view.dart';
import '../../features/projects/views/submit_offer_view.dart';
import '../../features/portfolio/controllers/create_portfolio_item_controller.dart';
import '../../features/portfolio/controllers/portfolio_controller.dart';
import '../../features/portfolio/views/create_portfolio_item_view.dart';
import '../../features/portfolio/views/portfolio_item_detail_view.dart';
import '../../features/portfolio/views/portfolio_view.dart';
import '../models/project_document.dart';
import '../../features/notifications/controllers/notifications_controller.dart';
import '../../features/notifications/views/notifications_view.dart';
import '../../features/profile/controllers/add_review_controller.dart';
import '../../features/profile/controllers/engineer_profile_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/views/add_review_view.dart';
import '../../features/wallet/controllers/add_card_controller.dart';
import '../../features/wallet/controllers/saved_cards_controller.dart';
import '../../features/wallet/controllers/wallet_controller.dart';
import '../../features/wallet/controllers/wallet_deposit_payment_controller.dart';
import '../../features/wallet/views/add_card_view.dart';
import '../../features/wallet/views/saved_cards_view.dart';
import '../../features/wallet/views/wallet_view.dart';
import '../../features/profile/controllers/engineer_bank_details_controller.dart';
import '../../features/profile/views/engineer_bank_details_view.dart';
import '../../features/profile/views/engineer_profile_view.dart';
import '../../features/profile/views/my_reviews_view.dart';
import '../../features/profile/controllers/my_reviews_controller.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/splash/controllers/splash_controller.dart';
import '../../features/splash/views/splash_view.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  static const completeProfile = '/complete-profile';
  static const engineerRegistrationGate = '/engineer-registration-gate';
  static const home = '/home';
  static const profile = '/profile';
  static const createProject = '/create-project';
  static const inviteEngineerChooseProject = '/invite-engineer-project';
  static const projectDetail = '/project-detail';
  static const submitOffer = '/submit-offer';
  static const acceptOfferPayment = '/accept-offer-payment';
  static const cardPayment = '/card-payment';
  static const chat = '/chat';
  static const chatByProject = '/chat-project';
  static const chatsList = '/chats';
  static const engineerProfile = '/engineer-profile';
  static const engineerBankDetails = '/engineer-bank-details';
  static const notifications = '/notifications';
  static const addReview = '/add-review';
  static const myReviews = '/my-reviews';
  static const wallet = '/wallet';
  static const savedCards = '/saved-cards';
  static const addCard = '/add-card';
  static const portfolio = '/portfolio';
  static const createPortfolioItem = '/create-portfolio-item';
  static const portfolioItemDetail = '/portfolio-item-detail';
  static const splash = '/splash';
  static const adminHome = '/admin';
  static const adminWithdrawals = '/admin/withdrawals';
  static const adminBankVerifications = '/admin/bank-verifications';
  static const adminWallets = '/admin/wallets';
  static const adminUsers = '/admin/users';
  static const adminUserEdit = '/admin/user-edit';
  static const adminProjects = '/admin/projects';
  static const adminProjectEdit = '/admin/project-edit';
  static const adminProjectSupportChat = '/admin/project-support-chat';

  static List<GetPage> get routes => [
        GetPage(
          name: splash,
          page: () => const SplashView(),
          binding: BindingsBuilder(() {
            Get.put(SplashController());
          }),
        ),
        GetPage(
          name: login,
          page: () => const LoginView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<LoginController>(() => LoginController());
          }),
        ),
        GetPage(
          name: signup,
          page: () => const SignupView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SignupController>(() => SignupController());
          }),
        ),
        GetPage(
          name: otp,
          page: () => const OtpView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<OtpController>(() => OtpController());
          }),
        ),
        GetPage(
          name: completeProfile,
          page: () => const CompleteProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<CompleteProfileController>(() => CompleteProfileController());
          }),
        ),
        GetPage(
          name: engineerRegistrationGate,
          page: () => const EngineerRegistrationGateView(),
        ),
        GetPage(
          name: home,
          page: () => const HomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<HomeController>(() => HomeController());
            // Eager put: MyProjectsView (home tab) uses GetView — must exist when tab opens; avoid duplicate on re-entry.
            if (!Get.isRegistered<MyProjectsController>()) {
              Get.put<MyProjectsController>(MyProjectsController());
            }
            Get.lazyPut<BrowseProjectsController>(() => BrowseProjectsController());
            Get.lazyPut<BrowseEngineersController>(() => BrowseEngineersController());
            Get.lazyPut<ProfileController>(() => ProfileController());
          }),
        ),
        GetPage(
          name: adminHome,
          page: () => const AdminHomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AdminHomeController>(() => AdminHomeController());
          }),
        ),
        GetPage(
          name: adminWithdrawals,
          page: () => const AdminWithdrawalsView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminWithdrawalsController>()) {
              Get.delete<AdminWithdrawalsController>(force: true);
            }
            Get.put(AdminWithdrawalsController());
          }),
        ),
        GetPage(
          name: adminBankVerifications,
          page: () => const AdminBankVerificationsView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminBankVerificationsController>()) {
              Get.delete<AdminBankVerificationsController>(force: true);
            }
            Get.put(AdminBankVerificationsController());
          }),
        ),
        GetPage(
          name: adminWallets,
          page: () => const AdminWalletsView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminWalletsController>()) {
              Get.delete<AdminWalletsController>(force: true);
            }
            Get.put(AdminWalletsController());
          }),
        ),
        GetPage(
          name: adminUsers,
          page: () => const AdminUsersView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminUsersController>()) {
              Get.delete<AdminUsersController>(force: true);
            }
            Get.put(AdminUsersController());
          }),
        ),
        GetPage(
          name: adminUserEdit,
          page: () => const AdminUserEditView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminUserEditController>()) {
              Get.delete<AdminUserEditController>(force: true);
            }
            Get.put(AdminUserEditController());
          }),
        ),
        GetPage(
          name: adminProjects,
          page: () => const AdminProjectsView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminProjectsController>()) {
              Get.delete<AdminProjectsController>(force: true);
            }
            Get.put(AdminProjectsController());
          }),
        ),
        GetPage(
          name: adminProjectEdit,
          page: () => const AdminProjectEditView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminProjectEditController>()) {
              Get.delete<AdminProjectEditController>(force: true);
            }
            Get.put(AdminProjectEditController());
          }),
        ),
        GetPage(
          name: adminProjectSupportChat,
          page: () => const AdminProjectSupportChatView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<AdminProjectSupportChatController>()) {
              Get.delete<AdminProjectSupportChatController>(force: true);
            }
            Get.put(AdminProjectSupportChatController());
          }),
        ),
        GetPage(
          name: createProject,
          page: () => const CreateProjectView(),
          binding: BindingsBuilder(() {
            final args = Get.arguments as Map<String, dynamic>?;
            Get.lazyPut<CreateProjectController>(() => CreateProjectController()
              ..invitedEngineerId = args?['invitedEngineerId'] as String? ?? ''
              ..invitedEngineerName = args?['invitedEngineerName'] as String? ?? '');
          }),
        ),
        GetPage(
          name: inviteEngineerChooseProject,
          page: () => const InviteEngineerProjectView(),
          binding: BindingsBuilder(() {
            if (Get.isRegistered<InviteEngineerProjectController>()) {
              Get.delete<InviteEngineerProjectController>(force: true);
            }
            Get.put(InviteEngineerProjectController());
          }),
        ),
        GetPage(
          name: projectDetail,
          page: () => const ProjectDetailView(),
        ),
        GetPage(
          name: chat,
          page: () => const ChatView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChatController>(() {
              final args = Get.arguments as Map<String, dynamic>?;
              return ChatController()
                ..project = args?['project']
                ..otherUserId = args?['otherUserId']
                ..otherUserName = args?['otherUserName'];
            });
          }),
        ),
        GetPage(
          name: chatByProject,
          page: () {
            final projectId = Get.arguments as String?;
            return ChatLandingView(projectId: projectId ?? '');
          },
        ),
        GetPage(
          name: chatsList,
          page: () => const ChatsListView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChatsListController>(() => ChatsListController());
          }),
        ),
        GetPage(
          name: cardPayment,
          page: () => const CardPaymentView(),
          binding: BindingsBuilder(() {
            final args = Get.arguments;
            if (args is Map && args['mode'] == 'wallet') {
              if (Get.isRegistered<WalletDepositPaymentController>()) {
                Get.delete<WalletDepositPaymentController>(force: true);
              }
              final amt = (args['amount'] as num?)?.toDouble() ?? 0.0;
              Get.put(WalletDepositPaymentController(depositAmount: amt));
            } else {
              if (Get.isRegistered<WalletDepositPaymentController>()) {
                Get.delete<WalletDepositPaymentController>(force: true);
              }
            }
          }),
        ),
        GetPage(
          name: acceptOfferPayment,
          page: () => const AcceptOfferPaymentView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AcceptOfferPaymentController>(() {
              final args = Get.arguments as Map<String, dynamic>?;
              return AcceptOfferPaymentController()
                ..offer = args?['offer']
                ..project = args?['project'];
            });
          }),
        ),
        GetPage(
          name: submitOffer,
          page: () => const SubmitOfferView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SubmitOfferController>(() {
              final p = Get.arguments;
              return SubmitOfferController()..project = p is ProjectDocument ? p : null;
            });
          }),
        ),
        GetPage(
          name: engineerProfile,
          page: () => const EngineerProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<EngineerProfileController>(() {
              final id = Get.arguments;
              return EngineerProfileController()..engineerId = id is String ? id : '';
            });
          }),
        ),
        GetPage(
          name: engineerBankDetails,
          page: () => const EngineerBankDetailsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<EngineerBankDetailsController>(() => EngineerBankDetailsController());
          }),
        ),
        GetPage(
          name: notifications,
          page: () => const NotificationsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<NotificationsController>(() => NotificationsController());
          }),
        ),
        GetPage(
          name: wallet,
          page: () => const WalletView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<WalletController>(() => WalletController());
          }),
        ),
        GetPage(
          name: savedCards,
          page: () => const SavedCardsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SavedCardsController>(() => SavedCardsController());
          }),
        ),
        GetPage(
          name: addCard,
          page: () => const AddCardView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AddCardController>(() => AddCardController());
          }),
        ),
        GetPage(
          name: addReview,
          page: () => const AddReviewView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AddReviewController>(() {
              final args = Get.arguments as Map<String, dynamic>?;
              return AddReviewController()
                ..engineerId = args?['engineerId'] as String? ?? ''
                ..projectId = args?['projectId'] as String?;
            });
          }),
        ),
        GetPage(
          name: myReviews,
          page: () => const MyReviewsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<MyReviewsController>(() => MyReviewsController());
          }),
        ),
        GetPage(
          name: profile,
          page: () => const ProfileView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ProfileController>(() => ProfileController());
          }),
        ),
        GetPage(
          name: portfolio,
          page: () => const PortfolioView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<PortfolioController>(() => PortfolioController());
          }),
        ),
        GetPage(
          name: createPortfolioItem,
          page: () => const CreatePortfolioItemView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<CreatePortfolioItemController>(() => CreatePortfolioItemController());
          }),
        ),
        GetPage(
          name: portfolioItemDetail,
          page: () => const PortfolioItemDetailView(),
        ),
      ];
}
