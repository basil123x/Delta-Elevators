import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.delta_elevator"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    defaultConfig {
        applicationId = "com.delta_elevator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            val alias = keyProperties["keyAlias"] as String?
            val keyPasswordValue = keyProperties["keyPassword"] as String?
            val storePath = keyProperties["storeFile"] as String?
            val storePasswordValue = keyProperties["storePassword"] as String?
            if (!alias.isNullOrBlank() &&
                !keyPasswordValue.isNullOrBlank() &&
                !storePath.isNullOrBlank() &&
                !storePasswordValue.isNullOrBlank()
            ) {
                keyAlias = alias
                keyPassword = keyPasswordValue
                storeFile = file(storePath)
                storePassword = storePasswordValue
            }
        }
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            val storePath = keyProperties["storeFile"] as String?
            val store = storePath?.let { file(it) }
            val releaseSigning = signingConfigs.getByName("release")
            if (!keyPropertiesFile.exists() || store == null || !store.exists()) {
                throw GradleException(
                    """
                    Cannot sign the release AAB: upload keystore is missing.

                    Create android/key.properties (gitignored) with:
                      storePassword=...
                      keyPassword=...
                      keyAlias=...
                      storeFile=/absolute/path/to/your-upload-keystore.jks

                    Use the SAME Play Store upload keystore from previous releases
                    (this app is already published; a new keystore will be rejected).
                    """.trimIndent(),
                )
            }
            signingConfig = releaseSigning
        }
    }
}

flutter {
    source = "../.."
}