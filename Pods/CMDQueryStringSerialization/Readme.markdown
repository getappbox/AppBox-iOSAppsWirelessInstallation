# CMDQueryStringSerialization

![Pod Version](https://cocoapod-badges.herokuapp.com/v/CMDQueryStringSerialization/badge.png)
![Pod Platform](https://cocoapod-badges.herokuapp.com/p/CMDQueryStringSerialization/badge.png)
![Pod License](https://cocoapod-badges.herokuapp.com/l/CMDQueryStringSerialization/badge.png)

Easily convert between dictionaries and query strings in iOS and OS X. The API is similar to `NSJSONSerialization`.

## Usage

```objc
NSString *queryString = [CMDQueryStringSerialization queryStringWithDictionary:dictionary];
```

`CMDQueryStringSerialization` supports arrays encoded in one of the following three formats:

* `key=value1&key=value2`
* `key[]=value1&key[]=value2`
* `key=value1,value2`

`CMDQueryStringWritingOptions` contains options that map to each of these formats, with `CMDQueryStringWritingOptionArrayRepeatKeysWithBrackets` being the default if no option is passed.

## License

`CMDQueryStringSerialization` is released under the MIT License.
