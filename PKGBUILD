pkgname=sddm-theme-snow-crash
pkgver=0.2.0
pkgrel=1
pkgdesc='Minimal static SDDM theme with the Snow Crash wallpaper'
arch=('any')
url=''
license=('MIT')
depends=('sddm')
source=("snow-crash-sddm.tar.gz")
sha256sums=('SKIP')

package() {
  install -dm755 "$pkgdir/usr/share/sddm/themes/snow-crash"
  cp -r "$srcdir/snow-crash-sddm/." "$pkgdir/usr/share/sddm/themes/snow-crash/"
}
