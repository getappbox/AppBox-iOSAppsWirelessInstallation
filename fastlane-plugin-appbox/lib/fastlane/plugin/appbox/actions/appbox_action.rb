require 'fastlane/action'
require_relative '../helper/appbox_helper'

module Fastlane
  module Actions
    class AppboxAction < Action
      def self.run(params)
        UI.message(params)

        ipa_path = Actions.lane_context[ Actions::SharedValues::IPA_OUTPUT_PATH ]
        UI.message("IPA PATH - #{ipa_path}")

        if params[:emails]
          emails = params[:emails]
          UI.message("Emails - #{emails}")
        end

        if params[:message]
          message = params[:message]
          UI.message("Message - #{message}")
        end

        if params[:appbox_path]
          appbox_path = "#{params[:appbox_path]}/Contents/MacOS/AppBox"
        else
          appbox_path =  "/Applications/AppBox.app/Contents/MacOS/AppBox"
        end
        UI.message("AppBox Path - #{appbox_path}")

        # Start AppBox
        UI.message("Starting AppBox...")
        exit_status = system("exec #{appbox_path} ipa='#{ipa_path}' email='#{emails}' message='#{message}'")
        UI.message("Back to the Fastlane from AppBox with Success: #{exit_status}")
        
      end

      def self.description
        "Deploy Development, Ad-Hoc and In-house (Enterprise) iOS applications directly to the devices from your Dropbox account."
      end

      def self.authors
        ["Vineet Choudhary"]
      end

      #def self.return_value
        # If your method provides a return value, you can describe here what it does
      #end

      def self.details
        "Deploy Development, Ad-Hoc and In-house (Enterprise) iOS applications directly to the devices from your Dropbox account."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :emails,
                                       env_name: "FL_APPBOX_EMAILS",
                                       description: "Comma-separated list of email address that should receive application installation link",
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :appbox_path,
                                       env_name: "FL_APPBOX_PATH",
                                       description: "If you've setup AppBox in the different directory then you need to mention that here. Default is '/Applications/AppBox.app'",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_APPBOX_MESSAGE",
                                       description: "Attach personal message in the email. Supported Keywords: The {PROJECT_NAME} - For Project Name, {BUILD_VERSION} - For Build Version, and {BUILD_NUMBER} - For Build Number",
                                       optional: true),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include? platform
      end
    end
  end
end
