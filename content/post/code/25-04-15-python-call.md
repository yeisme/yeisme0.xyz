+++
title = "Python 使用 `__call__` 实现装饰器"
date = "2025-04-15T01:22:01+08:00"
description = ""
tags = []
categories = []
series = []
aliases = []
image = ""
draft = false
+++
# python装饰器实现

## `__call__`

```python
    def __call__(self, fn: AnyCallable) -> HTTPRouteHandler:
        """Replace a function with itself."""
        if not is_async_callable(fn):
            if self.sync_to_thread is None:
                warn_implicit_sync_to_thread(fn, stacklevel=3)
        elif self.sync_to_thread is not None:
            warn_sync_to_thread_with_async_callable(fn, stacklevel=3)

        super().__call__(fn)
        return self

```

```python
def __call__(self, fn: AsyncAnyCallable) -> Self:
        """Replace a function with itself."""
        self._fn = fn
        return self
```

在 Python 中，使用类创建装饰器可以通过实现 `__call__` 方法并结合 `__init__` 方法来完成。以下是常见的几种方式：

---

### **1. 基础装饰器类**
定义一个类，通过 `__init__` 接收被装饰的函数，`__call__` 实现装饰逻辑。

```python
class SimpleDecorator:
    def __init__(self, func):
        self.func = func  # 保存被装饰的函数
    
    def __call__(self, *args, **kwargs):
        print("Before function execution")
        result = self.func(*args, **kwargs)
        print("After function execution")
        return result

@SimpleDecorator
def greet(name):
    print(f"Hello, {name}!")

greet("Alice")
# 输出:
# Before function execution
# Hello, Alice!
# After function execution
```

#### Python装饰器原理解析

在这段代码中，能够传递`func`参数是因为Python装饰器的工作原理。当你使用`@`语法装饰一个函数时，Python实际上执行了一个特殊的操作流程：

#### 装饰器执行过程

1. 当Python解释器执行到`@SimpleDecorator`装饰器时，它会先定义`greet`函数
2. 然后将`greet`函数作为参数传递给`SimpleDecorator`构造函数
3. 最终用`SimpleDecorator`的实例替换原始的`greet`函数

实际上，这个语法糖：
```python
@SimpleDecorator
def greet(name):
    print(f"Hello, {name}!")
```

等同于：
```python
def greet(name):
    print(f"Hello, {name}!")

greet = SimpleDecorator(greet)  # 将函数作为参数传递给装饰器
```

#### 调用过程

当执行`greet("Alice")`时：

1. 实际上是在调用`SimpleDecorator`的实例
2. 由于该类实现了`__call__`方法，它的实例是可调用的对象
3. 调用时执行了`__call__`方法，该方法中调用了保存的原始函数`self.func`

---

### **2. 带参数的装饰器类**
如果需要装饰器接受额外参数，需分两层处理：外层类接收参数，内层处理函数。

```python
class ParametrizedDecorator:
    def __init__(self, prefix):
        self.prefix = prefix  # 保存装饰器参数
    
    def __call__(self, func):
        def wrapper(*args, **kwargs):
            print(f"{self.prefix}: Before function execution")
            result = func(*args, **kwargs)
            print(f"{self.prefix}: After function execution")
            return result
        return wrapper

@ParametrizedDecorator("DEBUG")
def add(a, b):
    return a + b

print(add(2, 3))
# 输出:
# DEBUG: Before function execution
# DEBUG: After function execution
# 5
```

---

### **3. 支持函数和方法的装饰器类**
若装饰器需要同时支持函数和类方法，需确保正确处理 `self` 参数：

```python
class UniversalDecorator:
    def __init__(self, func):
        self.func = func
    
    def __call__(self, *args, **kwargs):
        print("Decorator logic here")
        return self.func(*args, **kwargs)
    
    # 解决方法绑定问题（可选）
    def __get__(self, instance, owner):
        from functools import partial
        return partial(self.__call__, instance)

class MyClass:
    @UniversalDecorator
    def my_method(self):
        print("Method called")

obj = MyClass()
obj.my_method()
# 输出:
# Decorator logic here
# Method called
```

---

### **4. 装饰类本身的装饰器类**
通过修改或扩展类的行为，装饰器可以作用于类：

```python
class ClassDecorator:
    def __init__(self, cls):
        self.cls = cls  # 保存被装饰的类
    
    def __call__(self, *args, **kwargs):
        # 修改实例化行为
        instance = self.cls(*args, **kwargs)
        # 添加新方法
        instance.new_method = lambda: print("New method added!")
        return instance

@ClassDecorator
class MyClass:
    def __init__(self, value):
        self.value = value

obj = MyClass(10)
obj.new_method()  # 输出: New method added!
```

---

### **5. 可维护状态的装饰器类**
利用类的实例属性保存状态（如调用次数）：

```python
class StatefulDecorator:
    def __init__(self, func):
        self.func = func
        self.count = 0  # 记录调用次数
    
    def __call__(self, *args, **kwargs):
        self.count += 1
        print(f"Function called {self.count} times")
        return self.func(*args, **kwargs)

@StatefulDecorator
def say_hello():
    print("Hello!")

say_hello()  # 输出: Function called 1 times → Hello!
say_hello()  # 输出: Function called 2 times → Hello!
```

---

### **6. 继承实现装饰器**
通过继承基类扩展装饰器功能：

```python
class BaseDecorator:
    def __init__(self, func):
        self.func = func
    
    def __call__(self, *args, **kwargs):
        return self.func(*args, **kwargs)

class TimingDecorator(BaseDecorator):
    import time
    def __call__(self, *args, **kwargs):
        start = self.time.time()
        result = super().__call__(*args, **kwargs)
        end = self.time.time()
        print(f"Function took {end - start:.2f} seconds")
        return result

@TimingDecorator
def slow_function():
    import time
    time.sleep(1)

slow_function()  # 输出: Function took 1.00 seconds
```

