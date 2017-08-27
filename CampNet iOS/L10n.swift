// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name
enum L10n {

  enum About {
    /// Version %@ (%@)
    static func version(_ p1: String, _ p2: String) -> String {
      return L10n.tr("Localizable", "about.version", p1, p2)
    }
  }

  enum AccountDetail {

    enum DeleteAccountAlert {

      enum Actions {
        /// Cancel
        static let cancel = L10n.tr("Localizable", "account_detail.delete_account_alert.actions.cancel")
        /// Delete Account
        static let delete = L10n.tr("Localizable", "account_detail.delete_account_alert.actions.delete")
      }
    }
  }

  enum HotspotHelper {
    /// Campus network managed by CampNet
    static let displayName = L10n.tr("Localizable", "hotspot_helper.display_name")
  }

  enum Notifications {

    enum HistoryError {
      /// Unable to Update History of "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.history_error.title", p1)
      }
    }

    enum LoginError {
      /// Unable to Login "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.login_error.title", p1)
      }
    }

    enum LoginIpError {
      /// Unable to Login %@
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.login_ip_error.title", p1)
      }
    }

    enum LogoutError {
      /// Unable to Logout "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.logout_error.title", p1)
      }
    }

    enum LogoutSessionError {
      /// Unable to Logout "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.logout_session_error.title", p1)
      }
    }

    enum LogsCopied {
      /// Logs copied
      static let title = L10n.tr("Localizable", "notifications.logs_copied.title")
    }

    enum ProfileError {
      /// Unable to Update Profile of "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.profile_error.title", p1)
      }
    }

    enum StatusError {
      /// Unable to Update Status of "%@"
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.status_error.title", p1)
      }
    }

    enum UsageAlert {
      /// Up to %@ can still be used this month.
      static func body(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.usage_alert.body", p1)
      }
      /// "%@" has used %d%% of maximum usage
      static func title(_ p1: String, _ p2: Int) -> String {
        return L10n.tr("Localizable", "notifications.usage_alert.title", p1, p2)
      }
    }
  }

  enum Overview {

    enum Chart {

      enum LimitLines {
        /// Free
        static let free = L10n.tr("Localizable", "overview.chart.limit_lines.free")
        /// Max
        static let max = L10n.tr("Localizable", "overview.chart.limit_lines.max")
      }
    }

    enum LoginButton {

      enum Captions {
        /// Logging In…
        static let loggingIn = L10n.tr("Localizable", "overview.login_button.captions.logging_in")
        /// Logging Out…
        static let loggingOut = L10n.tr("Localizable", "overview.login_button.captions.logging_out")
        /// Login
        static let login = L10n.tr("Localizable", "overview.login_button.captions.login")
        /// Logout
        static let logout = L10n.tr("Localizable", "overview.login_button.captions.logout")
        /// Logout "%@"
        static func logoutOthers(_ p1: String) -> String {
          return L10n.tr("Localizable", "overview.login_button.captions.logout_others", p1)
        }
        /// Off-campus
        static let offcampus = L10n.tr("Localizable", "overview.login_button.captions.offcampus")
        /// Unknown
        static let unknown = L10n.tr("Localizable", "overview.login_button.captions.unknown")
      }
    }

    enum LoginUnknownNetworkAlert {
      /// "Auto Login" will only be effective in networks marked as "On Campus".
      static let message = L10n.tr("Localizable", "overview.login_unknown_network_alert.message")
      /// Do You Want to Mark "%@" as "On Campus"?
      static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "overview.login_unknown_network_alert.title", p1)
      }

      enum Actions {
        /// Later
        static let later = L10n.tr("Localizable", "overview.login_unknown_network_alert.actions.later")
        /// Mark As "On Campus"
        static let markAsOnCampus = L10n.tr("Localizable", "overview.login_unknown_network_alert.actions.mark_as_on_campus")
      }
    }

    enum LogoutWhenAutoLoginAlert {
      /// Auto Login Will Be Triggered After Logging Out. Do You Want to Logout Anyway?
      static let title = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.title")

      enum Actions {
        /// Cancel
        static let cancel = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.actions.cancel")
        /// Logout
        static let logout = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.actions.logout")
      }
    }

    enum Titles {
      /// No Accounts
      static let noAccounts = L10n.tr("Localizable", "overview.titles.no_accounts")
    }
  }

  enum SessionDetail {

    enum LogoutAlert {

      enum Actions {
        /// Cancel
        static let cancel = L10n.tr("Localizable", "session_detail.logout_alert.actions.cancel")
        /// Logout Device
        static let logout = L10n.tr("Localizable", "session_detail.logout_alert.actions.logout")
      }
    }
  }

  enum Sessions {

    enum DeleteConfirmationButton {
      /// Logout
      static let title = L10n.tr("Localizable", "sessions.delete_confirmation_button.title")
    }
  }

  enum Settings {

    enum UsageAlert {

      enum Values {
        /// Off
        static let off = L10n.tr("Localizable", "settings.usage_alert.values.off")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length nesting type_body_length type_name

extension L10n {
  fileprivate static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
