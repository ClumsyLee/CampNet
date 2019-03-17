// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {
  /// "%@"
  internal static func quoted(_ p1: String) -> String {
    return L10n.tr("Localizable", "quoted", p1)
  }

  internal enum CampNetError {
    /// The account is in arrears.
    internal static let arrears = L10n.tr("Localizable", "CampNet_error.arrears")
    /// Internal error, please contact the developer.
    internal static let internalError = L10n.tr("Localizable", "CampNet_error.internalError")
    /// Invalid configuration file, please contact the developer.
    internal static let invalidConfiguration = L10n.tr("Localizable", "CampNet_error.invalidConfiguration")
    /// Network error, please try again later.
    internal static let networkError = L10n.tr("Localizable", "CampNet_error.networkError")
    /// Not connected to the campus network.
    internal static let offcampus = L10n.tr("Localizable", "CampNet_error.offcampus")
    /// Please login first.
    internal static let offline = L10n.tr("Localizable", "CampNet_error.offline")
    /// Invalid username or password, please re-enter password in "Accounts".
    internal static let unauthorized = L10n.tr("Localizable", "CampNet_error.unauthorized")
    /// Unknown error: %@
    internal static func unknown(_ p1: String) -> String {
      return L10n.tr("Localizable", "CampNet_error.unknown", p1)
    }
  }

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

  internal enum Chart {
    internal enum LimitLines {
      /// Free
      internal static let free = L10n.tr("Localizable", "chart.limit_lines.free")
      /// Max
      internal static let max = L10n.tr("Localizable", "chart.limit_lines.max")
    }
  }

  internal enum HotspotHelper {
    /// CampNet managed network
    internal static let displayName = L10n.tr("Localizable", "hotspot_helper.display_name")
  }

  internal enum Notifications {
    internal enum DonationRequest {
      /// In order to stay on the App Store, I have to pay 688 RMB a year. I need your love to keep this open source project alive.
      internal static let body = L10n.tr("Localizable", "notifications.donation_request.body")
      /// Campnet Has Auto-logged in %d times for You
      internal static func title(_ p1: Int) -> String {
        return L10n.tr("Localizable", "notifications.donation_request.title", p1)
      }
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
    internal enum DonateError {
      /// Failed to Donate
      internal static let title = L10n.tr("Localizable", "support_us.donate_error.title")
    }
    internal enum RestoreResult {
      /// Failed to Restore
      internal static let failed = L10n.tr("Localizable", "support_us.restore_result.failed")
      /// Nothing to Restore
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
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
