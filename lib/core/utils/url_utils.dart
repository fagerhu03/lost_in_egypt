/// Rewrites Google profile-image CDN URLs to force JPEG delivery.
///
/// `lh3.googleusercontent.com` normally returns WebP, which crashes Android's
/// ImageDecoder on certain devices. Appending `=rj` instructs the CDN to serve
/// JPEG instead. Any existing format/size suffix (e.g. `=s96-c`) is replaced.
String sanitizeProfileImageUrl(String url) {
  if (url.isEmpty) return url;
  if (!url.contains('lh3.googleusercontent.com')) return url;
  final slashIdx = url.lastIndexOf('/');
  final eqIdx = url.lastIndexOf('=');
  if (eqIdx > slashIdx) {
    return '${url.substring(0, eqIdx)}=rj';
  }
  return '$url=rj';
}
