// Version configuration for Smart Saver app
const VERSION_CONFIG = {
  // Current app version
  current_version: {
    android: '1.0.0',
    ios: '1.0.0',
    build_number: {
      android: 1,
      ios: 1
    }
  },
  
  // Minimum required version (force update below this)
  minimum_version: {
    android: '1.0.0',
    ios: '1.0.0',
    build_number: {
      android: 1,
      ios: 1
    }
  },
  
  // Force update settings
  force_update: {
    enabled: false, // Set to true to force update
    message: 'A new version of Smart Saver is available. Please update to continue using the app.',
    title: 'Update Required',
    update_button_text: 'Update Now',
    later_button_text: 'Later'
  },
  
  // Store URLs
  store_urls: {
    android: 'https://play.google.com/store/apps/details?id=com.example.smart_saver',
    ios: 'https://apps.apple.com/app/smart-saver/id123456789'
  },
  
  // Update types
  update_types: {
    FORCE: 'force',      // User must update to continue
    RECOMMENDED: 'recommended', // User can skip but recommended
    OPTIONAL: 'optional' // User can skip
  }
};

// Version comparison utility
function compareVersions(version1, version2) {
  const v1Parts = version1.split('.').map(Number);
  const v2Parts = version2.split('.').map(Number);
  
  for (let i = 0; i < Math.max(v1Parts.length, v2Parts.length); i++) {
    const v1Part = v1Parts[i] || 0;
    const v2Part = v2Parts[i] || 0;
    
    if (v1Part > v2Part) return 1;
    if (v1Part < v2Part) return -1;
  }
  
  return 0;
}

// Check if update is required
function isUpdateRequired(clientVersion, clientBuildNumber, platform) {
  const minVersion = VERSION_CONFIG.minimum_version[platform];
  const minBuildNumber = VERSION_CONFIG.minimum_version.build_number[platform];
  
  // Compare version strings
  const versionComparison = compareVersions(clientVersion, minVersion);
  
  // If versions are equal, check build numbers
  if (versionComparison === 0) {
    return clientBuildNumber < minBuildNumber;
  }
  
  return versionComparison < 0;
}

// Get update information
function getUpdateInfo(clientVersion, clientBuildNumber, platform) {
  const isRequired = isUpdateRequired(clientVersion, clientBuildNumber, platform);
  const isForceEnabled = VERSION_CONFIG.force_update.enabled;
  
  return {
    update_required: isRequired,
    force_update: isRequired && isForceEnabled,
    update_type: isRequired && isForceEnabled ? VERSION_CONFIG.update_types.FORCE : 
                 isRequired ? VERSION_CONFIG.update_types.RECOMMENDED : 
                 VERSION_CONFIG.update_types.OPTIONAL,
    current_version: VERSION_CONFIG.current_version[platform],
    minimum_version: VERSION_CONFIG.minimum_version[platform],
    store_url: VERSION_CONFIG.store_urls[platform],
    message: VERSION_CONFIG.force_update.message,
    title: VERSION_CONFIG.force_update.title,
    update_button_text: VERSION_CONFIG.force_update.update_button_text,
    later_button_text: VERSION_CONFIG.force_update.later_button_text
  };
}

module.exports = {
  VERSION_CONFIG,
  compareVersions,
  isUpdateRequired,
  getUpdateInfo
}; 