# 0.7.0

- Always return files as binaries - previously, when gzip was disabled, file
  content was in the form of IO data, which `Sitemapper.S3Store` would choke on.
  If you have your own implementation of `Sitemapper.Store`, this may be a
  breaking change for you.