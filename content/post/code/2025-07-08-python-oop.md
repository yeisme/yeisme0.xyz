+++
title = "Python 面向对象编程"
date = "2025-07-08T19:40:20+08:00"
description = ""
tags = ["Python", "OOP", "面向对象编程"]
categories = []
series = []
aliases = []
image = ""
draft = false
+++

# Python 面向对象编程

## 面向对象编程简介

面向对象编程（OOP）是一种编程范式，它使用“对象”来组织代码。对象是数据和方法的封装体，允许程序员创建可重用和可扩展的代码结构。

这篇文章我们主要学习 Python 中的面向对象编程（OOP）概念和实践，至于使用场景和优势，我们会在后续的文章中详细讨论。

OOP 的核心概念包括：

1. 类（Class）：定义对象的模板。
2. 对象（Object）：类的实例，包含数据和方法。
3. 继承（Inheritance）：允许新类从现有类继承属性和方法。
4. 封装（Encapsulation）：将数据和方法封装在对象内部，限制对外部的访问。
5. 抽象（Abstraction）：隐藏复杂性，只暴露必要的接口。
6. 接口（Interface）：定义类可以实现的方法集合。
7. 多态（Polymorphism）：允许不同类的对象以相同的方式调用方法。
8. 方法重载（Method Overloading）：允许同名方法根据参数类型或数量的不同而有不同的实现。
9. 方法重写（Method Overriding）：子类可以重写父类的方法以提供特定实现。
10. 抽象类（Abstract Class）：不能实例化的类，只能被继承，用于定义接口和部分实现。
11. 组合（Composition）：通过包含其他对象来构建复杂对象，而不是继承。

我们将通过多个案例来演示这些概念。

## 类和对象

```python
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return f"{self.name} makes a sound."

```

在 Python 中，类使用 `class` 关键字定义。`__init__` 方法是构造函数，用于初始化对象的属性。`self` 参数指向当前对象实例。

这里的 `speak` 方法是一个普通方法，它可以被对象调用。

```python
dog = Animal("Dog")
print(dog.speak())  # 输出: Dog makes a sound.
```

## 继承

```python
# 继承
class Dog(Animal):
    def speak(self):
        return f"{self.name} barks."


class Cat(Animal):
    def speak(self):
        return f"{self.name} meows."

```

这里的 `Dog` 和 `Cat` 类继承自 `Animal` 类，并重写了 `speak` 方法。这样，子类可以拥有父类的属性和方法，同时也可以定义自己的特定行为。

```python
dog = Dog("Buddy")
cat = Cat("Whiskers")
print(dog.speak())  # 输出: Buddy barks.
print(cat.speak())  # 输出: Whiskers meows.
```

## 封装

封装是将数据和方法封装在对象内部，限制对外部的访问。可以使用私有属性和方法来实现封装。Python 中通过在属性或方法名前加双下划线（`__`）或者单下划线（`_`）来表示私有属性或方法。

双下划线表示该属性或方法是受保护的，通常不应该被外部访问，但仍然可以通过 `_ClassName__attribute` 的方式访问。单下划线表示该属性或方法是私有的，通常不应该被外部访问，但仍然可以通过类的实例访问。

Python 中没有严格的访问控制，仅能通过命名约定来实现，这并不是强制的而是约定俗成的，好在 LSP 代码提示可以帮助我们遵循这些约定，在 Pylance 中，提高类型检查模式为 Basic、Standard 和 Strict，有助于发现潜在的错误。

```python
# 封装
class Person:
    def __init__(self, name, age):
        self.name = name  # 公有属性
        self.__age = age  # 私有属性

    def get_age(self):  # 公有方法
        return self.__age

    def set_age(self, age):  # 公有方法
        if age > 0:
            self.__age = age
        else:
            print("年龄必须大于0")


bob = Person("Bob", 30)
print(bob.name)  # 输出: Bob

print(bob.get_age())  # 输出: 30
# print(bob.__age)
"""
Traceback (most recent call last):
  File "C:/Users/yeisme/code/language_dev/python_dev/learn_project/oop_python/oop_python2.py", line 21, in <module>
    print(bob.__age)
          ^^^^^^^^^
AttributeError: 'Person' object has no attribute '__age'
"""

print(bob._Person__age)  # 输出: 30
# 在 LSP basic 以上模式下，bob._Person__age 会有代码提示：
# 无法访问类“Person”的属性“_Person__age”
#  属性“_Person__age”未知PylancereportAttributeAccessIssue
```

将方法变成属性 `@property`：可以使用 `@property` 装饰器将方法变成属性，这样可以更方便地访问和修改属性，同时仍然可以控制访问权限。

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.__age = age

    @property
    def age(self):
        return self.__age

    @age.setter
    def age(self, value):
        if value > 0:
            self.__age = value
        else:
            print("年龄必须大于0")
bob = Person("Bob", 30)
print(bob.age)  # 输出: 30
bob.age = 35
print(bob.age)  # 输出: 35
bob.age = -5  # 输出: 年龄必须大于0
```

## 抽象

抽象可以使用抽象类和抽象方法来实现抽象。Python 中可以使用 `abc` 模块来定义抽象类和抽象方法。

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self):
        pass

    @abstractmethod
    def perimeter(self):
        pass
```

在这个例子中，`Shape` 是一个抽象类，定义了两个抽象方法 `area` 和 `perimeter`。任何继承自 `Shape` 的类都必须实现这两个方法。

```python
class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius
    def area(self):
        return 3.14 * self.radius ** 2
    def perimeter(self):
        return 2 * 3.14 * self.radius
class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    def area(self):
        return self.width * self.height
    def perimeter(self):
        return 2 * (self.width + self.height)

circle = Circle(5)
rectangle = Rectangle(4, 6)
print(f"Circle area: {circle.area()}")  # 输出: Circle area: 78.5
print(
    f"Circle perimeter: {circle.perimeter()}"
)  # 输出: Circle perimeter: 31.400000000000002
print(f"Rectangle area: {rectangle.area()}")  # 输出: Rectangle area: 24
print(f"Rectangle perimeter: {rectangle.perimeter()}")  # 输出: Rectangle perimeter: 20
```

除了隐藏复杂性，抽象更深层次的目的是**定义一套“契约” (Contract)**。当一个类继承自一个抽象基类（ABC）时，它就等于签署了一份契约，承诺自己一定会提供 ABC 中定义的所有抽象方法和属性。这带来了几个关键好处：

- **保证代码的一致性和可靠性**：任何符合 `Shape` 契约的对象（如 `Circle`, `Rectangle`），我们都可以放心地调用它的 `.area()` 方法，而不用关心它内部到底是如何计算的。
- **促进多态 (Polymorphism)**：我们可以编写一个函数，它的参数类型是抽象的 `Shape`，然后可以向这个函数传入任何 `Shape` 的具体子类实例。

如果少实现了抽象方法，Python 会抛出 `TypeError`。

```python
class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height
# 这里没有实现 perimeter 方法，会抛出 TypeError

Traceback (most recent call last):
  File "C:\Users\yeisme\code\language_dev\python_dev\learn_project\oop_python\oop_python3.py", line 35, in <module>
    rectangle = Rectangle(4, 6)
TypeError: Can't instantiate abstract class Rectangle without an implementation for abstract method 'perimeter'
```

这种“一个接口，多种实现”的能力就是多态，在 Python 中抽象类就是一个实现多态的手段。

几乎所有的框架（如 Web 框架 Django/Flask，数据科学库 Scikit-learn）都大量使用抽象类来定义插件、中间件或模型的接口，让用户可以轻松地扩展框架功能。

## 接口和多态

### A) 形式化接口 (Formal Interface)

接口在 Python 中通常通过抽象类来实现。接口定义了一组方法，这些方法可以被任何实现该接口的类所使用。这里的“实现”指的是类必须提供这些方法的具体实现。

我们改一下上面的 Shape 抽象类的定义，使其更像一个接口：

```python
from abc import ABC, abstractmethod


class IShape(ABC):
    @abstractmethod
    def area(self):
        pass

    @abstractmethod
    def perimeter(self):
        pass


class Circle(IShape):
    def __init__(self, radius):
        self.radius = radius

    def area(self):
        return 3.14 * self.radius**2

    def perimeter(self):
        return 2 * 3.14 * self.radius


class Rectangle(IShape):
    def __init__(self, width, height):
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height

    def perimeter(self):
        return 2 * (self.width + self.height)


def print_area_and_perimeter(shape: IShape):
    print(f"Area: {shape.area()}, Perimeter: {shape.perimeter()}")


circle = Circle(5)
rectangle = Rectangle(4, 6)

print_area_and_perimeter(circle)  # 输出: Area: 78.5, Perimeter: 31.400000000000002
print_area_and_perimeter(rectangle)  # 输出: Area: 24, Perimeter: 20

```

`print_area_and_perimeter` 函数接受任何实现了 `IShape` 接口的对象，这就是多态的体现。我们可以传入 `Circle` 或 `Rectangle` 的实例，而不需要关心它们的具体实现细节。

### 非形式化接口 (Informal Interface) 与鸭子类型

Python 中的多态还可以通过鸭子类型（Duck Typing）来实现。鸭子类型是一种动态类型检查的方式，强调对象的行为而不是对象的类型。

如果一个对象具有某些方法或属性，那么它就可以被视为实现了某种接口，而不需要显式地声明它实现了该接口。

```python
from abc import ABC, abstractmethod


class IShape(ABC):
    @abstractmethod
    def area(self):
        pass

    @abstractmethod
    def perimeter(self):
        pass


class Circle:
    def __init__(self, radius):
        self.radius = radius

    def area(self):
        return 3.14 * self.radius**2

    def perimeter(self):
        return 2 * 3.14 * self.radius


class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height

    def perimeter(self):
        return 2 * (self.width + self.height)


def print_area_and_perimeter(shape):
    try:
        print(f"Area: {shape.area()}, Perimeter: {shape.perimeter()}")
    except AttributeError as e:
        print(f"Error: {e}. 没有实现 area 或 perimeter 方法。")


circle = Circle(5)
rectangle = Rectangle(4, 6)

print_area_and_perimeter(circle)  # 输出: Area: 78.5, Perimeter: 31.400000000000002
print_area_and_perimeter(rectangle)  # 输出: Area: 24, Perimeter: 20

```

- **核心理念**：“如果一个对象走起来像鸭子，叫起来像鸭子，那么它就是一只鸭子。”
- **非强制性**：我们不关心对象的类型，只关心它在运行时**是否具有我们需要的方法**。
- **灵活性**：这种方式使得代码更加灵活，可以接受任何具有特定方法的对象，而不需要显式地声明它们实现了某个接口。

鸭子类型的优势在于它允许更大的灵活性和可扩展性。你可以创建一个新的类，只要它实现了 `area` 和 `perimeter` 方法，就可以被 `print_area_and_perimeter` 函数接受，而不需要修改函数本身。

缺点也是显而易见的：如果传入的对象没有实现所需的方法，代码只会在运行时抛出异常，当然，使用 LSP 同样可以帮助我们在编写代码时发现这些问题，当我们将 类型检查模式提高到 Basic、Standard 或 Strict 时，Pylance 会提示我们可能存在的问题。

我们将类型检查模式提高到 basic，以确保所有实现都符合接口的要求，将 perimeter 方法从 `IShape` 接口中删除，看看会发生什么：

```python

class Rectangle:
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height

    # def perimeter(self):
    #     return 2 * (self.width + self.height)


def print_area_and_perimeter(shape: IShape):
    try:
        print(f"Area: {shape.area()}, Perimeter: {shape.perimeter()}")
    except AttributeError as e:
        print(f"Error: {e}. 没有实现 area 或 perimeter 方法。")


circle: Circle = Circle(5)
rectangle: Rectangle = Rectangle(4, 6)

print_area_and_perimeter(
    shape=circle
)  # 输出: Area: 78.5, Perimeter: 31.400000000000002
print_area_and_perimeter(shape=rectangle)  # 输出: Area: 24, Perimeter: 20
#无法将“Circle”类型的参数分配给函数“print_area_and_perimeter”中类型为“IShape”的参数“shape”
#   “Circle”不可分配给“IShape”PylancereportArgumentType

```

### Python 内置的多态无处不在

其实，你在写的每一天 Python 代码中都在不自觉地使用多态。

- **`+` 运算符**：
  - `2 + 3` 执行的是整数加法。
  - `'hello' + ' ' + 'world'` 执行的是字符串拼接。
  - `[1, 2] + [3, 4]` 执行的是列表合并。 `+` 运算符根据操作对象的不同，展现出不同的行为，这就是多态。
- **`len()` 函数**：
  - `len('a string')` 返回字符串长度。
  - `len([1, 2, 3])` 返回列表元素个数。
  - `len({'a': 1, 'b': 2})` 返回字典键值对数量。 `len()` 能作用于任何实现了 `__len__` 方法的对象，这也是多态的体现。

## 方法重写

我们通过继承来实现方法重写。

```python
# 方形, 继承自矩形，方法重写
class Square(Rectangle):
    def __init__(self, side_length):
        super().__init__(side_length, side_length)

    def __str__(self):
        return f"Square with side length {self.width}"

```

Square 类继承自 Rectangle 类，并重写了 `__init__` 方法。这里的 `super()` 函数调用了父类的构造函数，以确保正确初始化宽度和高度。

```python
square = Square(4)
print(square)  # 输出: Square with side length 4
print(f"Area: {square.area()}")  # 输出: Area: 16
print(f"Perimeter: {square.perimeter()}")  # 输出: Perimeter: 16
```

当我们在 IDE 中，在 `square.perimeter()` 处代码跳转，会发现它实际上是调用了父类 `Rectangle` 的 `perimeter()` 方法。这就是方法重写的效果：子类可以根据需要修改或扩展父类的方法行为。

## 方法重载

Python 不支持传统意义上的方法重载（即同名方法根据参数类型或数量的不同而有不同的实现）。

```cpp
class MathUtils {
    public:
        int add(int a, int b) {
            return a + b;
        }

        double add(double a, double b) {
            return a + b;
        }

        int add(int a, int b, int c) {
            return a + b + c;
        }
};
```

在那些语言中，你可以定义多个同名方法，只要它们的参数列表不同。但在 Python 中，如果你在同一个类里定义了两个同名方法，后一个定义会无条件地覆盖前一个。

但是，我们可以通过默认参数、可变参数或类型检查来模拟方法重载。

```python
class MathUtils:
    @staticmethod
    def add(a, b, c=0):
        return a + b + c

print(MathUtils.add(1, 2))        # 输出: 3
print(MathUtils.add(1, 2, 3))     # 输出: 6
print(MathUtils.add(1.5, 2.5))    # 输出: 4.0
```

或者**使用可变数量的参数 (`*args`, `**kwargs`)\*\*

```python
class Calculator:
    def add(self, *args):
        # *args 会将所有位置参数打包成一个元组 (tuple)
        return sum(args)

calc = Calculator()
print(calc.add(1))          # 输出: 1
print(calc.add(1, 2, 3))    # 输出: 6
print(calc.add(5, 5, 5, 5)) # 输出: 20
```

使用单分派泛型函数 (`functools.singledispatch`)：当你想根据第一个参数的类型来改变函数行为时，这才是最接近传统重载的方式。

不过实际上我们在 Python 中很少需要使用这种方式，因为 Python 的动态类型特性和鸭子类型已经足够灵活。大家想要了解更多关于单分派泛型函数的内容，可以参考 PEP 443，本人了解有限，以下是 PEP 443 的链接：[PEP 443 -- Single-dispatch generic functions](https://peps.python.org/pep-0443/)

## 组合

组合是通过包含其他对象来构建复杂对象，组合允许我们在运行时动态地改变对象的行为。

“组合优于继承” (Composition Over Inheritance) 原则：在设计类时，优先考虑组合而不是继承。组合可以提供更大的灵活性和可扩展性，同时避免了继承带来的复杂性和耦合。

这个原则建议我们，在构建类与类之间的关系时，应优先考虑使用组合（一个类包含另一个类的实例，即 'has-a' 关系），而不是继承（一个类是另一个类的子类，即 'is-a' 关系）。

我们把场景切换到后端开发中一个非常常见的任务：**构建一个用户通知系统**。这个例子能非常清晰地展示出“组合优于继承”在实际工程中的重要性。

### 场景：后端用户通知系统

假设我们正在开发一个电商网站的后端。当某些事件发生时，我们需要通知用户，例如：

- 用户下单成功。
- 用户重置密码。
- 有可疑登录活动，触发安全警报。

通知的渠道可能有多种：电子邮件（Email）、短信（SMS）、App 推送（Push Notification）。

#### 第 1 步：初版设计（陷入继承的思维陷阱）

一个熟悉面向对象的开发者很自然地会想到用继承来设计这个系统。

- 创建一个抽象基类 `BaseNotifier`，定义一个 `send` 方法作为接口。
- 为每种通知渠道创建一个具体的子类：`EmailNotifier`、`SmsNotifier`。

这个设计看起来很标准，代码如下：

```python
# --- 继承方案 ---

from abc import ABC, abstractmethod

# 定义一个抽象的通知器基类
class BaseNotifier(ABC):
    @abstractmethod
    def send(self, user_id, message):
        pass

# 为每个渠道创建具体的子类
class EmailNotifier(BaseNotifier):
    def send(self, user_id, message):
        print(f"CONNECTING TO SMTP SERVER...")
        print(f"SENDING EMAIL to user {user_id}: {message}")

class SmsNotifier(BaseNotifier):
    def send(self, user_id, message):
        print(f"CONNECTING TO SMS GATEWAY...")
        print(f"SENDING SMS to user {user_id}: {message}")

# --- 在业务逻辑中使用 ---

# 密码重置服务，只需要邮件通知
password_reset_notifier = EmailNotifier()
password_reset_notifier.send("user-123", "Your password has been reset.")

# 订单成功服务，只需要短信通知
order_notifier = SmsNotifier()
order_notifier.send("user-456", "Your order #T12345 has been confirmed.")

```

到目前为止，这个系统工作得很好，结构清晰，似乎没什么问题。

#### 第 2 步：需求升级（继承方案的崩溃）

现在，产品经理提出了新的需求：

1. **对于“安全警报”，必须同时通过 Email 和 SMS 发送通知**，以确保用户能立即收到。
2. 对于“订单发货”，我们需要同时通过 **Email 和 App 推送**来通知用户。
3. 未来我们可能要加入 Slack、微信等更多通知渠道，并且任意组合它们。

现在，我们用继承该怎么办？

- **实现“Email + SMS”通知**：
  - 创建一个 `EmailAndSmsNotifier` 类？它应该继承 `EmailNotifier` 还是 `SmsNotifier`？还是两个都继承（多重继承）？多重继承会立刻让代码变得复杂。
  - 如果创建了 `EmailAndSmsNotifier`，里面的 `send` 方法是调用父类方法还是复制代码？复制代码会违反 DRY 原则。
- **组合爆炸**：
  - 按照这个思路，我们很快就需要创建 `EmailAndPushNotifier`、`SmsAndPushNotifier`，甚至 `EmailAndSmsAndPushNotifier`... 每增加一种通知渠道，可能需要创建的组合类就会呈指数级增长。这完全不可维护。

我们发现，**继承的 “is-a”（是一个）关系在这里是错误的**。一个“安全警报通知器”**不是一个**“邮件通知器”，它也**不是一个**“短信通知器”。正确的描述是，一个“安全警报通知器”**拥有**发送邮件和发送短信的**能力**。

#### 第 3 步：组合方案（构建灵活、可扩展的通知服务）

我们转换思路，将每个通知渠道视为一个独立的、可插拔的“组件”或“处理器”。然后我们创建一个“通知服务”，这个服务**拥有（has-a）**一个或多个渠道组件。

```python
# --- 组合方案 ---

# 1. 定义每个渠道的处理器。它们是独立的，不需要继承。
#    （为了类型提示和接口统一，可以有一个简单的ABC，但不是必须的）
class EmailHandler:
    def send(self, user_id, message):
        print(f"CONNECTING TO SMTP SERVER...")
        print(f"SENDING EMAIL to user {user_id}: {message}")

class SmsHandler:
    def send(self, user_id, message):
        print(f"CONNECTING TO SMS GATEWAY...")
        print(f"SENDING SMS to user {user_id}: {message}")

class PushNotificationHandler:
    def send(self, user_id, message):
        print(f"CONNECTING TO APN/FCM...")
        print(f"SENDING PUSH to user {user_id}: {message}")

# 2. 创建一个通用的“通知服务”，它“拥有”一个渠道列表
class NotificationService:
    def __init__(self, channels):
        # channels 是一个处理器实例的列表
        self.channels = channels

    def dispatch(self, user_id, message):
        print(f"--- Dispatching notification for user {user_id} ---")
        # 遍历所有拥有的渠道，并委托它们发送消息
        for channel in self.channels:
            channel.send(user_id, message)
        print("--- Dispatch complete ---\n")

# 3. 在业务逻辑中，像搭积木一样“组装”我们需要的通知服务

# 密码重置服务：只需要邮件
password_reset_service = NotificationService(channels=[EmailHandler()])
password_reset_service.dispatch("user-123", "Your password reset link is...")

# 安全警报服务：需要邮件 + 短信 + App推送
security_alert_service = NotificationService(
    channels=[
        EmailHandler(),
        SmsHandler(),
        PushNotificationHandler()
    ]
)
security_alert_service.dispatch("user-789", "[CRITICAL] A new device has signed into your account.")

# 订单发货服务：需要邮件 + App推送
shipping_service = NotificationService(
    channels=[
        EmailHandler(),
        PushNotificationHandler()
    ]
)
shipping_service.dispatch("user-456", "Your order #T12345 has been shipped!")
```

这个后端场景完美地诠释了“组合优于继承”的强大之处：

1. **极高的灵活性和可配置性**
   - 在组合模式下，一个通知事件具体使用哪些渠道，可以变成**配置**。这些配置可以存储在数据库或配置文件中，在服务启动时动态加载。我们可以随时调整通知策略（例如，为“安全警报”增加一个`SlackHandler`），而**无需修改任何业务逻辑代码**，更不用重新部署服务。这是后端系统高可用和可维护性的关键。
2. **完美的扩展性（遵循开放/封闭原则）**
   - 当需要增加一种新的通知渠道（如 Slack）时，我们只需要创建一个新的 `SlackHandler` 类。这个系统对于**扩展是开放的**。而核心的 `NotificationService` 类和现有的业务逻辑完全不需要改动，它们对于**修改是封闭的**。
3. **松耦合与单一职责**
   - 每个 `Handler` 类只负责一件事情（如发送邮件），它的职责非常单一，易于开发、测试和维护。`NotificationService` 则扮演一个“调度器”的角色，它不关心消息是具体如何发送的，只负责委托任务。这使得系统的各个部分**高度解耦**。

## 结论

面向对象编程（OOP）是一个强大的编程范式，它通过类和对象的概念来组织代码。我们通过多个案例演示了 OOP 的核心概念，包括类、对象、继承、封装、抽象、多态、方法重载和组合。通过这些案例，我们可以看到 OOP 如何帮助我们构建可重用、可扩展和易于维护的代码结构。

虽然我们经常调侃 Python 是面向库编程，但 OOP 在 Python 中仍然是一个重要的编程范式。Python 的灵活性和动态特性使得 OOP 可以与其他编程范式（如函数式编程）无缝结合。
