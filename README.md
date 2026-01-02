WizardAO on macOS
===

This project installs and frames [HyperBEAM](https://hyperbeam.ar.io/) and [WizardAO](https://wao.eco/) on macOS in order to create disposable rapid dev environments for the AO computer.


Roadmap
---

 * [ ] Get `npm test` working
 * [ ] Contibute `apply_makefile_patches()` from `./hyperbeam.sh` to fix compilation on macOS to upstream HyperBEAM repo


Usage
---

```
./hyperbeam.sh install

# Ensure it runs
./hyperbeam.sh run

# Run tests
npm test
```
