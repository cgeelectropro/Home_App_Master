import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/theme/color.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:home_app/utils/error_handler.dart';
import 'package:home_app/utils/app_logger.dart';

class ProfilePage extends StatefulWidget {
  static const String route = '/profile';

  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  Future<void> _refreshUserData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.refreshUser();
      await AppLogger.log('User data refreshed');
    } catch (e) {
      await AppLogger.logError(
          'Failed to refresh user data', e, StackTrace.current);
      ErrorHandler.showErrorSnackBar(context, 'Failed to refresh profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/profileEdit',
            ).then((_) => _refreshUserData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<UserProvider, ThemeChanger>(
              builder: (context, userProvider, themeChanger, _) {
                final user = userProvider.user;

                if (user == null) {
                  return const Center(child: Text('User not found'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(22.0),
                              bottomRight: Radius.circular(22.0),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Hero(
                                tag: 'profile',
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        user.picture.isNotEmpty
                                            ? user.picture
                                            : 'https://via.placeholder.com/100',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Stats Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Consumer2<DeviceProvider, CollectionProvider>(
                            builder: (context, deviceProvider,
                                collectionProvider, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatCard(
                                    context,
                                    'Devices',
                                    deviceProvider.devices.length.toString(),
                                    Icons.devices,
                                    themeChanger.darkTheme,
                                  ),
                                  _buildStatCard(
                                    context,
                                    'Rooms',
                                    collectionProvider.collections.length
                                        .toString(),
                                    Icons.room,
                                    themeChanger.darkTheme,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Settings Section
                        Card(
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: const Text('Dark Mode'),
                                trailing: Switch(
                                  value: themeChanger.darkTheme,
                                  onChanged: (value) {
                                    themeChanger.toggleTheme();
                                  },
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Settings'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.help),
                                title: const Text('Help & Support'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  // Navigate to help page
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    bool isDarkTheme,
  ) {
    return Card(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDarkTheme
                  ? AppColors.iconsColor_dark
                  : AppColors.iconsColor_light,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
