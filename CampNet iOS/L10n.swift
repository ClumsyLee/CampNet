// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum About {
    /// Version %@ (%@)
    internal static func version(_ p1: String, _ p2: String) -> String {
      return L10n.tr("Localizable", "about.version", p1, p2)
    }
  }

  internal enum AccountDetail {
    internal enum DeleteAccountAlert {
      internal enum Actions {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "account_detail.delete_account_alert.actions.cancel")
        /// Delete Account
        internal static let delete = L10n.tr("Localizable", "account_detail.delete_account_alert.actions.delete")
      }
    }
  }

  internal enum Accounts {
    internal enum EmptyView {
      /// No Accounts
      internal static let title = L10n.tr("Localizable", "accounts.empty_view.title")
    }
  }

  internal enum HotspotHelper {
    /// Campus network managed by CampNet
    internal static let displayName = L10n.tr("Localizable", "hotspot_helper.display_name")
  }

  internal enum Notifications {
    internal enum DonationRequest {
      /// CampNet has auto-logged in %d times for you. Would you like to show some love to this open source project?
      internal static func body(_ p1: Int) -> String {
        return L10n.tr("Localizable", "notifications.donation_request.body", p1)
      }
      /// We Need Your Support!
      internal static let title = L10n.tr("Localizable", "notifications.donation_request.title")
    }
    internal enum HistoryError {
      /// Unable to Update History of "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.history_error.title", p1)
      }
    }
    internal enum LoadConfiguration {
      internal enum FetchError {
        /// Unable to Fetch Configuration
        internal static let title = L10n.tr("Localizable", "notifications.load_configuration.fetch_error.title")
      }
      internal enum ParseError {
        /// Unable to Parse Configuration
        internal static let title = L10n.tr("Localizable", "notifications.load_configuration.parse_error.title")
      }
    }
    internal enum LoginError {
      /// Unable to Login "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.login_error.title", p1)
      }
    }
    internal enum LoginIpError {
      /// Unable to Login %@
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.login_ip_error.title", p1)
      }
    }
    internal enum LogoutError {
      /// Unable to Logout "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.logout_error.title", p1)
      }
    }
    internal enum LogoutSessionError {
      /// Unable to Logout "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.logout_session_error.title", p1)
      }
    }
    internal enum LogsCopied {
      /// Logs Copied
      internal static let title = L10n.tr("Localizable", "notifications.logs_copied.title")
    }
    internal enum ProfileError {
      /// Unable to Update Profile of "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.profile_error.title", p1)
      }
    }
    internal enum StatusError {
      /// Unable to Update Status of "%@"
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.status_error.title", p1)
      }
    }
    internal enum UsageAlert {
      /// Up to %@ can still be used this month.
      internal static func body(_ p1: String) -> String {
        return L10n.tr("Localizable", "notifications.usage_alert.body", p1)
      }
      /// "%@" Has Used %d%% of Maximum Usage
      internal static func title(_ p1: String, _ p2: Int) -> String {
        return L10n.tr("Localizable", "notifications.usage_alert.title", p1, p2)
      }
    }
  }

  internal enum Overview {
    internal enum Chart {
      internal enum LimitLines {
        /// Free
        internal static let free = L10n.tr("Localizable", "overview.chart.limit_lines.free")
        /// Max
        internal static let max = L10n.tr("Localizable", "overview.chart.limit_lines.max")
      }
    }
    internal enum LoginButton {
      internal enum Captions {
        /// Logging In…
        internal static let loggingIn = L10n.tr("Localizable", "overview.login_button.captions.logging_in")
        /// Logging Out…
        internal static let loggingOut = L10n.tr("Localizable", "overview.login_button.captions.logging_out")
        /// Login
        internal static let login = L10n.tr("Localizable", "overview.login_button.captions.login")
        /// Logout
        internal static let logout = L10n.tr("Localizable", "overview.login_button.captions.logout")
        /// Logout "%@"
        internal static func logoutOthers(_ p1: String) -> String {
          return L10n.tr("Localizable", "overview.login_button.captions.logout_others", p1)
        }
        /// Off-campus
        internal static let offcampus = L10n.tr("Localizable", "overview.login_button.captions.offcampus")
        /// Unknown
        internal static let unknown = L10n.tr("Localizable", "overview.login_button.captions.unknown")
      }
    }
    internal enum LoginUnknownNetworkAlert {
      /// "Auto Login" will only be effective in networks marked as "On Campus".
      internal static let message = L10n.tr("Localizable", "overview.login_unknown_network_alert.message")
      /// Do You Want to Mark "%@" as "On Campus"?
      internal static func title(_ p1: String) -> String {
        return L10n.tr("Localizable", "overview.login_unknown_network_alert.title", p1)
      }
      internal enum Actions {
        /// Later
        internal static let later = L10n.tr("Localizable", "overview.login_unknown_network_alert.actions.later")
        /// Mark As "On Campus"
        internal static let markAsOnCampus = L10n.tr("Localizable", "overview.login_unknown_network_alert.actions.mark_as_on_campus")
      }
    }
    internal enum LogoutWhenAutoLoginAlert {
      /// Auto Login Will Be Triggered After Logging Out. Do You Want to Logout Anyway?
      internal static let title = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.title")
      internal enum Actions {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.actions.cancel")
        /// Logout
        internal static let logout = L10n.tr("Localizable", "overview.logout_when_auto_login_alert.actions.logout")
      }
    }
    internal enum Titles {
      /// No Accounts
      internal static let noAccounts = L10n.tr("Localizable", "overview.titles.no_accounts")
    }
  }

  internal enum SessionDetail {
    internal enum LogoutAlert {
      internal enum Actions {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "session_detail.logout_alert.actions.cancel")
        /// Logout Device
        internal static let logout = L10n.tr("Localizable", "session_detail.logout_alert.actions.logout")
      }
    }
  }

  internal enum Sessions {
    internal enum DeleteConfirmationButton {
      /// Logout
      internal static let title = L10n.tr("Localizable", "sessions.delete_confirmation_button.title")
    }
    internal enum EmptyView {
      /// No Online Devices
      internal static let title = L10n.tr("Localizable", "sessions.empty_view.title")
    }
  }

  internal enum Settings {
    internal enum UsageAlert {
      internal enum Values {
        /// Off
        internal static let off = L10n.tr("Localizable", "settings.usage_alert.values.off")
      }
    }
  }

  internal enum SupportUs {
    internal enum DonateButton {
      internal enum Title {
        /// Donated - Thank You!
        internal static let donated = L10n.tr("Localizable", "support_us.donate_button.title.donated")
      }
    }
    internal enum RestoreResult {
      /// Failed to restore
      internal static let failed = L10n.tr("Localizable", "support_us.restore_result.failed")
      /// Nothing to restore
      internal static let nothing = L10n.tr("Localizable", "support_us.restore_result.nothing")
      /// Restored!
      internal static let restored = L10n.tr("Localizable", "support_us.restore_result.restored")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  fileprivate static func tr(_ table: String, _ key: String) -> String {
    return NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
  }

  fileprivate static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
