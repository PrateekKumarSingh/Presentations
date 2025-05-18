#!/usr/bin/env pwsh
using namespace System.IO
using namespace System.Text
using namespace System.Text.Json

# create a memory stream to hold the data in-memory
# the memory stream is a performant way to hold data without locking the source
$memStream = [MemoryStream]::new()

# use the Utf8 Json Writer object
$jsonWriter = [Utf8JsonWriter]::new($memStream)

# indicate the JSON object is starting
$jsonWriter.WriteStartObject();

# now the JSON string is written
$jsonWriter.WriteString("ComputerName", "TestVM01");

# instruct the JSON object is ending
$jsonWriter.WriteEndObject();

# flush the json writer content to the stream
$jsonWriter.Flush();

# dispose of the json writer
$jsonWriter.Dispose();

# Get the string from the byte[] array from the memory stream
[Encoding]::UTF8.GetString($memStream.ToArray())