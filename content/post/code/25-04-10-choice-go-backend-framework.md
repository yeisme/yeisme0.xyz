+++
title = "如何选择你的 Golang 后端开发框架"
date = "2025-04-10T17:22:33+08:00"
description = ""
tags = []
categories = []
series = []
aliases = []
image = ""
draft = false
+++

# 如何选择你的 Golang 后端开发框架

## 引言

与 Java 生态中 Spring Boot 一家独大的情况不同，Go 的后端框架呈现出百花齐放的态势。这为开发者提供了丰富的选择，但也常常带来选择的困惑：Gin, Echo, Beego, Iris, net/http... 究竟哪一个才最适合我的项目？为了后来者不在纠结，我抛砖引玉一下，给大家介绍如何选择你的 Golang 后端开发框架。

我们将探讨不同框架的特点、适用场景以及选择时需要考虑的关键因素。无论你是倾向于构建传统的 RESTful API（如使用 Gin、Echo 等框架），还是需要支持 RPC 通信，亦或是对性能有极致要求（可以参考 [常见 Go Web 框架基准测试](https://github.com/smallnest/go-web-framework-benchmark) 的数据），希望本文能为你提供有价值的参考，让你在面对众多选择时不再迷茫。

## 对比分析

以下对比我当前使用最多的两个框架 gin vs go-zero，顺便梳理我的学习过程。

### Gin

[gin](https://github.com/gin-gonic/gin)

{{< figure src="image.png" alt="gin" >}}

优点:

- 丰富的功能集: 提供了开发 Web 应用所需的大部分核心功能：强大的路由（支持参数、分组、多种 HTTP 方法）、中间件支持（内置常用中间件如 Logger, Recovery，且易于编写自定义中间件）、JSON 绑定与验证、HTML 模板渲染、错误管理等。
- 庞大的社区和生态: 作为最流行的 Go Web 框架之一（GitHub 上 star 最多的 Golang 框架），拥有非常活跃的社区，文档、教程、示例和第三方扩展非常丰富，遇到问题容易找到解决方案。

缺点:

- 功能不足: 你需要手动维护你的组件，在正式开发前同样需要编写大量的样本代码，缺乏内置高级功能（如 OpenAPI 生成、复杂校验），需依赖第三方库。

去年春天学习了 gin 并在暑假期间打比赛（揭榜挂帅），完成了一个全栈项目，对当时的我来说，gin 已经完全够用，并且最终比赛成绩也和使用什么框架无关，选择更轻量、更自由方便的 gin 就显得很合理。

但是 gin 真的就适合你吗？当你需要进行 API 调试时，你就需要一个 API 调试工具，如果你有一个 openapi 文件，就能够非常方便的导入，当你使用 gin 作为开发框架，你就不得不在 go 文件里添加 swag 的注释，像这样

```go
// @title           Swagger Example API
// @version         1.0
// @description     This is a sample server celler server.
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.url    http://www.swagger.io/support
// @contact.email  support@swagger.io

// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html

// @host      localhost:8080
// @BasePath  /api/v1

// @securityDefinitions.basic  BasicAuth

// @externalDocs.description  OpenAPI
// @externalDocs.url          https://swagger.io/resources/open-api/
```

如果你使用过 fastapi springboot，你绝对不想用 gin 开发，这也是为什么这么多 java 开发者拒绝使用 golang 开发的原因，毕竟这和让一个现代人回归山上原始人的生活方式一样。

### go-zero

[go-zero](https://github.com/zeromicro/go-zero)

{{< figure src="image1.png" alt="go-zero" >}}

接下来就轮到 go-zero 了（可以简单理解为 Golang 的 springboot），如果你选择 go-zero，你还刚好是个新手，Go Zero 的学习曲线可能过于陡峭，对于非微服务应用，Go Zero 内置的功能可能显得有些过剩，我只能说，小子你很勇吗。

在各种基准测试中，Go Zero 的性能与其他流行的 Go Web 框架相比通常具有竞争力 。然而，在原始 HTTP 请求处理速度方面，Gin 等框架在综合基准测试中通常表现更好 。Echo 和 Fiber 也因其强大的性能而闻名，有时在特定的基准测试场景中会超越 Go Zero 。基于 fasthttp 的框架在这些比较中往往表现出最高的原始性能。

我去年 9 月了解 go-zero(在 CNCF的全景图中) ，今年 3 月才在熟悉 k8s 的基础上，开始我的第一个 go-zero 项目。

不过，说了这么多缺点，我却仍然推荐你用 go-zero。

优点:

- 完整的微服务解决方案：go-zero 不仅仅是一个 HTTP 框架，而是一个完整的微服务治理框架。它内置了服务发现、配置管理、分布式锁、分布式事务等功能，为微服务架构提供了全面支持。
- 代码生成器 goctl：这可能是 go-zero 最强大的特性之一。通过简单的 API 描述文件，goctl 可以自动生成服务框架、模型层代码、API 处理器等，大大提高了开发效率。比如这样一个简单的 API 定义：

```api
type (
    RegisterReq {
        Username string `json:"username"`
        Password string `json:"password"`
    }
    
    RegisterResp {
        Id int64 `json:"id"`
    }
)

service user-api {
    @handler Register
    post /api/users/register (RegisterReq) returns (RegisterResp)
}
```

并使用 `goctl api doc --dir . --o ./doc` 等命令生成 openapi 文件，使用其他 goctl 命令生成docker、k8s 以及其他语言的客户端调用代码(如果你知道 gRPC，你肯定知道我在说什么)

如果回到去年，我绝对先学 go-zero，少走一年弯路，使用 gin 的时候，你可能需要学 viper进行环境配置加载，gorm用于数据库操作，手动添加 Prometheus、jaeger、pprof的配置，现在只用在 yaml 文件里随便配置一下就能使用。

当然先从简单的 Gin 开始，随着项目复杂度增加再考虑迁移到 go-zero 等更全面的框架也很合理，但是__我还是推荐你先用 go-zero__，因为 golang 目前最重要的生态就是云原生，如果你不打算做云原生开发，那你选 go 就没有什么优势了。
