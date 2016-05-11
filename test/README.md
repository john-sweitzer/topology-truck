## Test a phase recipe

Run provision recipe in acceptance
```
test/runtruck.sh
```

Run deploy recipe in acceptance
```
test/runtruck.sh deploy
```

Run deploy recipe in rehearsal
```
test/runtruck.sh deploy rehearsal
```

NOTE: this will execute the provisioning recipe on your workstation, and may install gems (e.g. ssh provisioning). Test in a VM if this is a concern.

