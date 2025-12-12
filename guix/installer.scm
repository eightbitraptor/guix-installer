;;; Copyright © 2019 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2019,2024 David Wilson <david@daviwil.com>
;;; Copyright © 2022 Jonathan Brielmaier <jonathan.brielmaier@web.de>
;;; Copyright © 2024 Hilton Chain <hako@ultrarare.space>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

(define-module (nongnu system install)
  #:use-module (guix)
  #:use-module (guix channels)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mtools)
  #:use-module (gnu packages package-management)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu system)
  #:use-module (gnu system install)
  #:use-module (gnu system file-systems)
  #:use-module (gnu image)
  #:use-module (gnu system image)
  #:use-module (nongnu packages linux)
  #:export (installation-os-nonfree
            installation-image-nonfree))

(define %signing-key
  (plain-file "nonguix.pub" "\
(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

(define %channels
  (cons* (channel
          (name 'nonguix)
          (url "https://gitlab.com/nonguix/nonguix")
          (introduction
           (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
         %default-channels))

;; Root filesystem WITHOUT tmpfs /tmp - lets /tmp use the disk
(define %disk-live-file-systems
  (list (file-system
          (mount-point "/")
          (device (file-system-label "Guix_image"))
          (type "ext4"))))

(define installation-os-nonfree
  (operating-system
    (inherit installation-os)
    (kernel linux)
    (firmware (list linux-firmware))

    ;; Use disk-backed /tmp instead of RAM-based tmpfs
    (file-systems
     (append %disk-live-file-systems
             (list %pseudo-terminal-file-system
                   %shared-memory-file-system
                   %efivars-file-system
                   %immutable-store)))

    (services
      (cons*
        (simple-service 'channel-file etc-service-type
                        (list `("channels.scm" ,(local-file "channels.scm"))))
        (modify-services (operating-system-user-services installation-os)
          (guix-service-type
            config => (guix-configuration
                        (inherit config)
                        (guix (guix-for-channels %channels))
                        (authorized-keys
                          (cons* %signing-key
                                 %default-authorized-guix-keys))
                        (substitute-urls
                          `(,@%default-substitute-urls
                             "https://substitutes.nonguix.org"))
                        (channels %channels))))))

    (packages
      (append (list git curl stow vim emacs-no-x-toolkit)
              (operating-system-packages installation-os)))))

;; 28 GiB EFI disk image - leaves room for dotfiles partition on 32GB stick
(define installation-image-nonfree
  (image
   (inherit efi-disk-image)
   (operating-system installation-os-nonfree)
   (size (* 28 (expt 2 30)))))

installation-image-nonfree
