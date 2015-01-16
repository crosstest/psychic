# Running Code Samples

Psychic can be used to run code samples as well as tasks. It's designed so that if two (or more) projects have a similar set of samples than the same psychic commands should find and run the samples, even if the commands required to run them are drastically different. Psychic does this by:
- Searching for sample code by name rather than path
- Finding a task runner that is capable of running hte sample
- Adjusting how to pass input to the code sample, if necessary

## Showing Samples

You can check that psychic is finding the correct code sample before you attempt to run it. If you run:

```
$ psychic show sample "upload file"
```

This will show the information about the sample:

```
Sample Name:                          upload file
Tokens:
- authUrl
- username
- apiKey
- region
- containerName
- localFilePath
- remoteObjectName
Source File:                          ObjectStore/upload-object.php
```

If you pass the `--verbose` flag then Psychic will also display the code for the code sample, with syntax highlighting (if your terminal suports color).

The Tokens section shows what the tokens Psychic has detected that can be used for passing input to the code sample. See the documentation on [Tokens](tokens) for more details.

### Automatic detection

The default behavior is for psychic to search for with file with a name that is similar to the name of the sample. It will basically do a case-insensitive search for a file with a name that contains "upload file", ignoring whitespace. It will then display info about the sample it found:

```
$ bundle exec psychic show sample "upload file"
Sample Name:                          upload file
Tokens:                               (None)
Source File:                          storage/upload_file.rb
```

### Custom Map

You can tell Psychic exactly where to find a sample if it cannot be auto-detected. This is useful [crosstest](https://github.com/crosstest/crosstest) or any other situation where you want the same sample name to work across multiple projects even though the file names of the sample code have very different names.

You can do this by mapping sample names to files in your `psychic.yaml`. So you could add this:

```yaml
samples:
  upload file: ObjectStore/upload-object.php
```

Now `psychic show sample "upload file"` will find the correct sample, even though it has "object" rather than "file" in the name.

### Listing Samples

There is also a command for listing all known samples. See the [skeptic](https://github.com/crosstest/psychic-skeptic) project if you want to make ensure a project has a required set of samples.

```
$ bundle exec psychic list samples
upload file              ObjectStore/upload-object.php
change metadata          ObjectStore/update-object-metadata.php
get file                 ObjectStore/get-object.php
create networked server  Compute/create_server_with_network.php
create keypair           Compute/create_new_keypair.php
create load balancer     LoadBalancer/create-lb.php
secure load balancer     LoadBalancer/blacklist-ip-range.php
setup ssl                LoadBalancer/ssl-termination.php
delete load balancer     LoadBalancer/delete-lb.php
```

### Running a sample

Once you've checked that Psychic is detecting the correct sample, you can easily tell Psychic to run it with hte `psychic sample` command.

If you want to see how psychic would run the sample first, you can use the `--print` flag:

```
psychic sample "upload object" --print
```

### Dealing with Input

Psychic is able to run some code samples that require input. See the [Input documentation](input) for more details.

### Testing code samples

You can use Psychic's companion project, [Skeptic](https://github.com/crosstest/psychic-skeptic) to test code samples.
