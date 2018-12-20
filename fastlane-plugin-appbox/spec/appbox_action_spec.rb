describe Fastlane::Actions::AppboxAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The appbox plugin is working!")

      Fastlane::Actions::AppboxAction.run(nil)
    end
  end
end
