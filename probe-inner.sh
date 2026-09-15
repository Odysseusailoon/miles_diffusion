#!/bin/bash
echo "== dns in chroot:"
getent hosts api.github.com || echo "dns-fail"
echo "== t-done =="
