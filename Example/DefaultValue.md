# 为使用Codable解析接口数据提供默认值

## 1. 为什么需要提供默认值？

当前前后端进行数据交互均以json为标准格式。但是在数据字段可空性问题上，各端理解各不相同。

例如，我们协定以下数据：
```json
{
    "code": "C0000",
    "message": "",
    "result": {
         "age": 12,
          "name": "小明"
     }
}
```
但是实际环境中，我们可能收到下面数据：
```json
{
    "code": "C0000",
    "message": "",
    "result": {
         "age": null,
          "name": "小明"
     }
}
```
或者这样的：
```json
{
    "code": "C0000",
    "message": "",
    "result": {
          "name": "小明"
     }
}
```
当我们使用`Codable`来解析这样的数据时，就需要使用可选类型，才能避免数据解析失败的情况，然而在很多情况下，我们希望数据类型不是可选类型，以避免实际数据使用过程中使用过多的解包代码，因此我们想要在字段中设置默认值。

很不幸，单纯的`Codable`无法处理这个问题。

## 2. 解决方案

现在，在Swift5.2中，提供了解药，因为有了`propertyWrapper`。基于`propertyWrapper`，我们可以提供初步的解决方案。
如果原来我们要像下面那样定义数据模型：
```swift
struct Person: Codable {
    var age: Int?
    var name: String?
}
```
那么现在我们有了新的方式：
```swift
struct Person: Codable {
    @Default.Zero var age: Int
    @Default.Empty var name: String
}
```
以这种方式解析数据时，如果age为空或者age连键值对都不存在时，不再会产生数据解析失败的结果。在`Default.Zero`提供默认值0，在`Default.Empty`中提供了默认值`""`。

在`KfangNet/Decode/CodableDefaultValue.swift`中，提供了以下默认实现：
1. `@Default.True`
    针对`Bool`类型，需要设置默认值为`true`的情况
2. `@Default.False`
    针对`Bool`类型，需要设置默认值为`false`的情况
3. `@Default.Zero`
    针对整数类型`(Int/Int32/Int64/UInt/UInt32/UInt64)`，需要设置默认值为0的情况
    针对浮点数类型`(Float/Float32/Float64/Double)`,需要设置默认值为0.0的情况
4. `@Default.Empty`
    针对集合类型`(Array/Dictionary)`，需要设置默认值为空集合的情况。
    针对字符串，需要设置为`""`的情况。

对于其他需要设置默认值的类型，需要自定义实现。 

## 2.方案是如何工作的

在`KfangNet/Decode/CodableDefaultValue.swift`中，主要有以下内容：
-  `protocol DefaultValueProvidable`
    提供给外部以实现自定义默认
-  `struct Default`
    作为模块包装使用，核心在于`struct Wrapper<T:Codable>`, 基础类型的默认实现在`Default.ValueImpl`中。
-  `extension KeyedDecodingContainer`
    主要解决json中key不存在，导致数据解析失败的问题。
    
上面提到方案的核心在于`propertyWrapper`，那么在这里面的最核心的是`Wrapper<T>`了，它的全部实现是这样的：
```swift
@propertyWrapper
public struct Wrapper<T>: Codable where T: DefaultValueProvidable {
    public var wrappedValue: T.Value
    
    public init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        let value = try? container?.decode(T.Value.self)
        self.wrappedValue = value ?? T.defaultValue
    }
    
    public init() {
        wrappedValue = T.defaultValue
    }
}

```

这里的关键在于`Wrapper<T>`本身需要实现`Codable`，并且关联范型类型需要实现`DefaultValueProvidable`。

这里实现了`init(from decoder: Decoder) throws`方法，以可空的方式去解析数据，在数据为空时，返回由`DefaultValueProvidable`提供的`defaultValue`。

```swift
let container = try? decoder.singleValueContainer()
let value = try? container?.decode(T.Value.self)
self.wrappedValue = value ?? T.defaultValue
```
以上就是`Wraper`的最关键部分。

`DefaultValueProvidable`的主要意义是用于提供一个默认值，如果需要为自定义类型提供默认值，需要实现该协议。

`DefaultValueProvidable`的全部内容：
```swift
public protocol DefaultValueProvidable {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}
```

## 3. 如何自定义默认值

如果我们原本有这样一个数据结构：
```swift
struct Student: Codable {
    struct Class: Codable {
        var id: String?
        var name: String?
        var teacherId: String?
        var teacherName: String?
    }
    
    var id: String?
    var name: String?
    var age: String?
    var `class`: Class?
}
```

要想针对字段设置默认值很简单，只需要这样：
```swift
struct Student: Codable {
    struct Class: Codable {
        @Default.Empty var id: String
        @Default.Empty var name: String
        @Default.Empty var teacherId: String
        @Default.Empty var teacherName: String
    }
    
    @Default.Empty var id: String
    @Default.Empty var name: String
    @Default.Zero var age: Int
    @Default.Empty var `class`: Class
}
```

看起来似乎不错，但是实际运行起来，你会得到一个运行时错误，由这里发生的`fatalError("需要实现 defaultValue")`，因为我们并没有为`Class`提供`defaultValue`。

所以，还需要这么做：

```swift
extension Default.ValueImpl.Empty where T == Class {
    static var defaultValue: Class {
        return Class()
    }
}
```

这样就完成了默认值的处理了。这实际上就是扩展了`@Default.Empty`。

如果你觉得`@Default.Empty`命名不够准确，或者针对同一个类型你需要提供另外一个默认值，那么就还需要做更多的工作了。

假设你需要Class类提供两个默认值。
```json
// 1
{
    id: "1",
    name: "1班",
    teacherId: 1,
    teacherName: "小红"
}

// 2
{
    id: "2",
    name: "2班",
    teacherId: 2,
    teacherName: "小明"
}
```

第一步，实现`DefaultValueProvidable`

```swift
struct Hong: DefaultValueProvidable {
    static var defaultValue: Class {
        return Class(id: "1", name: "1班", teacherId: 1, teacherName: "小红")
    }
}

struct Ming: DefaultValueProvidable {
    static var defaultValue: Class {
        return Class(id: "2", name: "2班", teacherId: 2, teacherName: "小明")
    }
}
```

第二步，创建包装器类型别名
```swift
extension Default {
    public typealias Hong = Wrapper<Hong>
    public typealias Ming = Wrapper<Ming>
}
```

第三步，使用包装器

```swift
@Default.Hong var `class`: Class
@Default.Ming var `class`: Class
```

这样我就实现了两个自定义的默认值包装器。


## 4. 额外的说明

### a. 为什么`DefaultValueProvidable`需要使用关联类型？

主要是因为属性包装器不方便以参数的形式处理不同默认值，所以这里用不同类型实现`DefaultValueProvidable`协议，里面返回同一个类型的值来提供默认值，这样可以为返回同一个类型的不同值提供实现。

属性包装器以参数的形式处理，像这样：
```swift
@Default.Value(1) var age: Int
```
实现会比较复杂，所以这里采用了一种妥协的实现方式。

### b. 建议包装器类型别名放在`extension Default`里面。
主要是为了阅读和使用方便。这样当我们使用`@Default.xx`的时候就知道这个是为了默认值使用的。

### c. `@Default.xx`只是为了可读性而简化的。
比如`@Default.Zero var age: Int`, 其实等同于: `@Default. Wrapper<ValueImpl.Zero<Int>>`。

### c. 实际使用中需要注意类型是否适用。

在使用`@Default.Zero`和`@Default.Empty`的时候需要注意，这两者在定义上其实是一样的。

```swift
public struct Zero<T: Codable & Numeric> { }

public struct Empty<T: Codable & Sequence> { }

```

根据默认实现，如果类型实现了`Codable & Numeric`或者`Codable & Numeric`协议，那么在`@Default.Zero`和`@Default.Empty`时，是能编译通过的，但是实际运行时未必能正常工作，可能需要提供自定义实现。
