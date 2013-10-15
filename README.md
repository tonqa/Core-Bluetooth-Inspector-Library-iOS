### Under development

# Core Bluetooth Inspector Library

This library abstracts away all the cumbersome implementation details and a lot of error handling of CoreBluetooth. You can publish properties of your app to other apps and see live changes to properties from a remote app via Bluetooth. The library makes it even more easy to use Bluetooth for making changes to properties of your app from remote transparently having no manual effort at all.

## Inspection

Make your iOS or Mac App discoverable via Bluetooth with three easy steps:

   * Initialize the Bluetooth Inspector Service with a name
   * Add inspection for your properties you want others to read, write and and/or get notified about
   * Start the Inspector Service

Here the code to do just that:

  #import <AKCBInspection/AKCBInspection.h>

	@property (nonatomic, assign) BOOL observedValue;
	@property (nonatomic, retain) AKCBInspector *inspector;

	- (void)setup {

		# name can be a custom chosen service name or the app name
    	self.inspector = [[AKCBInspector alloc] initWithName:@"Test Server"];
	    [self.inspector inspectValueForKeyPath:@"observedValue"
    	                              ofObject:self
                                     options:(AKCB_READ|AKCB_WRITE|AKCB_NOTIFY)
        	                        identifier:@"observedValue"
            	                       context:nil];
	    [self.inspector start];
	}

Your app is then discoverable via Bluetooth out of the box. You can use the AppStore Apps 'Bluetooth Inspector' or 'LightBlue' (or others) to see the published Bluetooth services. See the video [].

## Observation

Of course, you can also write an own iOS or Mac app observing and changing the inspected values via Bluetooth with the following steps:

   * Set up the Bluetooth Observer with the name of the Inspector and set you as delegate
   * Discover all Bluetooth Inspectors (you can scan only for those with a specific name)
   * Connect to a chosen one and display its inspected property values
   * Call the read method if you want to manually read inspected properties
   * Call the write method if you want to interact with the properties
   * React to the notify delegate method (e.g. you can update the display of property values there)

Here the code to do just that (without error handling for better reading):

  #import <AKCBInspection/AKCBInspection.h>

	@property (nonatomic, retain) AKCBObserver *observer;

	- (void)setup {

	    AKCBObserver *observer = [[AKCBObserver alloc] initWithServerName:@"Test Server"];
    	observer.delegate = self;

	    [observer discoverPeripherals:^(CBPeripheral *peripheral , NSError *error) {
          [observer stopDiscovery];
	        [observer connectToPeripheral:peripheral  completion:^(NSArray *identifiers, NSError *error) {
            NSLog(@"You are connected, here you can start your reading & writing");
          }];
	    }];
	}

	- (void)doSomethingWithRemoteProperties {

	    [self.observer readValueWithIdentifier:@"observedValue" completion:^(id value, NSError *error) {
        		NSLog(@"Received remote property value '%@'", value);
	    }];

	    [self.observer writeValue:@YES withIdentifier:@"observedValue" completion:^(NSError *error) {
         		NSLog(@"Value was written");
    	}];

	}

	- (void)observerObservedChange:(AKCBObserver *)observer
    	                   keyPath:(NSString *)keyPath
        	                 value:(id)value
            	        identifier:(NSString *)identifier
                	       context:(id)context {
	    
	    NSLog(@"Observed change of property '%@' at remote device '%@'",
				keyPath, observer.connectedInspector.name);
	}


## Some implementation details

Under the hood the library uses Key-Value Coding (KVC) and Key-Value Observing (KVO) to read and write properties as well as get notified about property changes. It distributes the read, write and notify commands via Apple's new CoreBluetooth API based on Bluetooth 4.0 Low Energy (LE) or Bluetooth for Smart Devices. This is why the Inspector as well as the Observer must support Bluetooth 4.0 and have Bluetooth enabled.

The AKCBInspector actually is a CBPeriphalManager corresponding to a peripheral device (or server) in the Bluetooth LE specification. The AKCBObserver is a CBCentralManager managing a central device (or client) in the Bluetooth LE specification. So how does it work? Let's see in the sequence diagram below how the Inspector and the Observer interact.
The Inspector sets up a peripheral with a name and publishes a Bluetooth service for each of the inspected values. A Bluetooth service has a UUID and a name, we use it as the identifier of an inspected property. Each service has three characteristics named 'read' with UUID '0000', 'write' with UUID '0001' and 'notify' with UUID '0002'. On the first characteristic the built-in Bluetooth method for reading values is applied, the second uses the method for writing values and the third for notifying on value changes.

The Observer sets up a Central which connects to the chosen peripheral via name. It reads all offered Bluetooth LE services and their characteristics. The Observer offers methods to read and write the inspected values exposed in his interface. It also offers setting a delegate with a notify method, which is called each time an inspected property at the Inspector is changed.

It is easily possible to have multiple Inspectors (in many Apps on multiple devices) running at once and to inspect all of them at one Observer. It is also possible to have multiple Observers listening to changes of one Inspector. Thus, if you allow writing on the inspected properties please make sure to use proper synchronization mechanisms, e.g. making the property atomic or using synchronize blocks.

## TODOs

   * Error Handling
   * Add Mac Support
   * Create interface for example Apps
