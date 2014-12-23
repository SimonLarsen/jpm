## Service decomposition ##

Multiple client applications communicate with same client service.
Client service contacts multiple package provider servers
and builds database with registry over all of them.

                                          +----------+
                                     +--->| Server 1 |
    +------------+                   |    +----------+
    | CLI client |--                 | 
	+------------+  \->+--------+    |    +----------+
                       | Client |----|--->| Server i |
    +------------+   ->+--------+    |    +----------+
    | Web client |--/                |
    +------------+                   |    +----------+
                                     +--->| Server n |
                                          +----------+
