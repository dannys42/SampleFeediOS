# SampleFeediOS

[![Swift][swift-badge]][swift-url]

SampleFeed is a sample app that allows you to create "walls" and read and write to "posts" on those walls.  

It relies on the [SampleFeedServer](https://github.com/dannys42/SampleFeedServer) and shares code in [SampleFeedUtilities](https://github.com/dannys42/SampleFeedUtilities).

## Features

- Basic authentication for login
- Bearer tokens for API access


## Basic Architecture

The system relies on HTTP Basic Authentication for login and Bearer tokens for API access.  Once logged in, it will cache information from the server into a CoreData store allowing for offline use.

Wall syncing is currently triggered whenever the user is logged in.  And posts are synced when a wall is viewed.

In addition, when a wall or post is added, those trigger an additional sync event.


## Getting Started

Before building, edit Constants.swift and set the URL of your production server.


## TODO

- Delete walls/posts
- Images/Videos
- Push notification


## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat
[swift-url]: https://swift.org
