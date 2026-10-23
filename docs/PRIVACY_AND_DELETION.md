# Online data and deletion — local beta draft

Offline planets remain on the device and require no account. The online service receives nothing until the user configures a connection and performs an online action. Creating an identity stores a private account name and a maintained Identity password hash; the local beta does not collect email, location or device advertising identifiers.

Publishing explicitly sends the reviewed public snapshot: visible planet, creature and community names, terrain, representative wildlife, settlements, discoveries and public memories. It excludes the private seed/RNG, device diagnostics, timestamps from the private save, private favorites and filesystem paths. Public names may still contain personal information the player intentionally types; review them before sharing. A profile and its showcase each have private/friends/public settings. Both must be public for discovery. Reactions are four predefined friendly categories; there is no public chat.

The server stores invitation codes, friendships, blocks, up to three showcase revisions, reactions and bounded real activity. Logout revokes server tickets when reachable and always clears the client's in-memory session. Closing the app also discards tokens; there is no plaintext token file. No external push or third-party tracking is enabled.

Online profile → Delete account → confirm deletes the account and relational online data. It preserves the local world. Unpublish deletes the server showcase and retained versions. Profile visibility changes and blocks deny future reads, but cannot erase a snapshot or screenshot another person already obtained. Local file exports from 0.6 remain under the user's own control.

This draft describes a locally tested development service. No public operator, legal policy, public data region, backup retention or support channel is configured. Define and review those before any public beta, including deletion from hosted backups and account-recovery procedures.
