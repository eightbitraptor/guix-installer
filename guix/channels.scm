(define-module
 (ebr channels)
 #:use-module
 ((guix channels) #:prefix channels:)
 #:export
 (guix-channel
  nonguix-channel
  nonguix-substitute-url
  nonguix-substitute-primary-key))

(define guix-channel
  (channels:channel
   (name 'guix)
   (url "https://codeberg.org/guix/guix.git")
   (introduction
    (channels:make-channel-introduction
     "9edb3f66fd807b096b48283debdcddccfea34bad"
     (channels:openpgp-fingerprint
      "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))

(define nonguix-channel
  (channels:channel
   (name 'nonguix)
   (url "https://gitlab.com/nonguix/nonguix")
   (introduction
    (channels:make-channel-introduction
     "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
     (channels:openpgp-fingerprint
      "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))

(define guix-substitute-url "https://hydra-guix-129.guix.gnu.org/")

(define nonguix-substitute-url "https://substitutes.nonguix.org")

(define nonguix-substitute-primary-key
  '(public-key
    (ecc (curve Ed25519)
         (q "C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98"))))

(define %channels
  (list (channels:channel
         (inherit channels:%default-guix-channel)
         (commit "24d0c0a9510c8433a6dee749637b3c324744a68a"))
        (channels:channel
         (inherit nonguix-channel)
         (commit "53c477b3e0a45b3bd0036647ac805a8f5e8f71d0"))))

%channels
