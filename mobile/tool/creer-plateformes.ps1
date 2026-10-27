# À lancer UNE SEULE FOIS, depuis PowerShell, dans le dossier mobile :
#   cd C:\dev_web\temps-mort\mobile
#   powershell -ExecutionPolicy Bypass -File tool\creer-plateformes.ps1
#
# Crée les dossiers android/ (et ios/, utilisé plus tard sur un Mac) avec `flutter create`,
# puis règle l'identifiant définitif de l'app, la version Android visée et le nom affiché.
# Les fichiers existants (lib/, test/, pubspec.yaml) ne sont pas modifiés par flutter create.

$ErrorActionPreference = 'Stop'

if (Test-Path 'android') {
    Write-Host 'Le dossier android existe déjà : rien à faire.'
    exit 0
}

flutter create . --org fr.hasteria --project-name temps_mort --platforms android,ios

# flutter create ajoute un test d'exemple qui ne correspond pas à l'app : on le retire.
if (Test-Path 'test\widget_test.dart') { Remove-Item 'test\widget_test.dart' }

# Identifiant Google Play définitif (ne pourra plus changer après la première publication)
$gradle = 'android\app\build.gradle.kts'
$content = Get-Content $gradle -Raw
$content = $content -replace 'applicationId = "fr\.hasteria\.temps_mort"', 'applicationId = "fr.hasteria.tempsmort"'
# Google Play exige Android 16 (API 36) pour toute nouvelle app depuis le 31 août 2026
$content = $content -replace 'compileSdk = flutter\.compileSdkVersion', 'compileSdk = 36'
$content = $content -replace 'targetSdk = flutter\.targetSdkVersion', 'targetSdk = 36'
Set-Content $gradle $content -NoNewline

# Nom affiché sous l'icône
$manifest = 'android\app\src\main\AndroidManifest.xml'
(Get-Content $manifest -Raw) -replace 'android:label="temps_mort"', 'android:label="Temps Mort"' | Set-Content $manifest -NoNewline

Write-Host ''
Write-Host 'Plateformes créées. Vérifiez puis commitez :'
Write-Host '  git add android ios .metadata'
Write-Host '  git commit -m "chore(mobile): dossiers android et ios générés par flutter create"'
Write-Host 'Puis : flutter test, et flutter run sur la tablette branchée.'
