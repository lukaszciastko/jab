## [0.0.1] - 5 May 2020

* Initial Jab library implementation

## [0.0.2] - 5 May 2020

* Added a usage example

## [0.0.3] - 5 May 2020

* Added the option to use root as the main dependency injector (e.g. for testing purposes).

## [0.0.4] - 2 June 2020

* Breaking change: If an instance of Service cannot be found in the Widget tree, Jab will attempt to find the Service instance in all injectors which are currently initialized.