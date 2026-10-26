import unittest
from custom.profile import GitHubComponent, Profile

class ProfileTests(unittest.TestCase):
    def test_default_profile_is_valid(self):
        self.assertEqual(Profile().validate(), [])

    def test_unknown_base_is_not_silently_accepted(self):
        profile = Profile(base="arch")
        self.assertTrue(any("no installer adapter" in error for error in profile.validate()))

    def test_kde_requires_compatible_display_manager(self):
        profile = Profile(desktop_environment="kde-plasma", display_manager="gdm3")
        self.assertTrue(any("KDE Plasma" in error for error in profile.validate()))

    def test_package_names_are_validated(self):
        profile = Profile(packages=["sudo", "--option; rm -rf /"])
        self.assertTrue(any("Invalid package name" in error for error in profile.validate()))

    def test_remote_repository_commands_are_not_a_recipe(self):
        profile = Profile(github_components=[GitHubComponent(
            url="https://github.com/example/project",
            recipe="../install.sh",
        )])
        self.assertTrue(any("Unsafe recipe path" in error for error in profile.validate()))

    def test_untrusted_hosts_are_rejected(self):
        profile = Profile(github_components=[GitHubComponent(url="https://example.com/user/repo")])
        self.assertTrue(any("github.com" in error for error in profile.validate()))

if __name__ == "__main__":
    unittest.main()
