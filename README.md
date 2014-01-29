# r509-ocsp-stats

Record statistics for the r509-ocsp-responder. We track the VALID/REVOKED/UNKNOWN hits for each issuer and serial, and let you retrieve a snapshot of the hit statistics for _all_ serials.

# Warning

This was an experiment in stats gathering when dealing with 10-100 million responses per day on a cluster of OCSP responders and is not recommended for general use. It is not currently under maintenance.
...
