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
          UI.message(emails)
        end

        exec "/Applications/AppBox.app/Contents/MacOS/AppBox ipa=#{ipa_path} emails=#{emails}"

        UI.message("The appbox plugin is working!")
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
                                       description: "Change to a specific version. This will replace the bump type value",
                                       optional: false),
        ]
      end

      def self.is_supported?(platform)
        [:ios].include? platform
      end
    end
  end
end
