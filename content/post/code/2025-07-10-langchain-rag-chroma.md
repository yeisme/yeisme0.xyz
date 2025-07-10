+++
title = "AI Agent 开发没有门槛 (1): LangChain RAG Chroma"
date = "2025-07-10T15:41:10+08:00"
description = ""
tags = ["AI", "LangChain", "RAG", "Chroma"]
categories = []
series = []
aliases = []
image = ""
draft = false
+++

# AI Agent 开发没有门槛 (1): LangChain RAG Chroma

## 前言

在本系列文章中，我们将介绍如何使用 LangChain 和 ChromaDB 来构建一个简单的 AI 应用。这个应用将能够处理用户的查询，并从知识库中检索相关信息。

想象一下，你即将参加一场开卷考试，规则允许你带一本书进入考场。解答问题时，你不仅可以依赖平时的知识积累，更关键的是，你可以随时翻阅这本书来寻找确切的答案。

当你遇到一个问题时，你的大脑会首先进行检索。如果相关知识已经深深印在你的脑海里，并且你对此非常有把握，你会直接作答。如果记忆有些模糊，你则会翻开书本，定位到相关的章节和段落，利用书中的权威内容来组织你的答案。如果连书中也找不到线索，你可能会（像许多学生一样）尝试根据自己的理解，合理地推测一下，毕竟考试不能留白，这很合理。

在这个比喻中，你的大脑就如同一个强大的 AI 大语言模型 (LLM)，而那本允许带入考场的书籍，便是我们为 AI 构建的外部知识库 (Knowledge Base)。AI 模型本身具备通用的世界知识，但通过结合一个精准、可控的外部知识库，它的回答能力和可靠性将得到质的飞跃。这个给 AI 一本书的过程，在人工智能领域被称为检索增强生成 (Retrieval-Augmented Generation, RAG)。

在本教程中，我们的目标就是使用 LangChain 这个强大的 AI 应用开发框架，为 AI 构建一个《第二大脑》。这个大脑将借助 ChromaDB 这个向量数据库作为知识库载体，从而能够针对我们自己的文档，实现精准的问答。这章文章的目的不是开发一个 毫秒级、高精度、高并发 的 RAG 应用，而是让你了解如何使用 LangChain 和 ChromaDB 来构建一个简单的 RAG 应用。我们将从基础开始，逐步引导你完成整个过程。最以后，我们将学习更多高级功能和优化技巧。

## 环境准备

- uv 0.7.19 (38ee6ec80 2025-07-02)

项目依赖

```
[project]
name = "rag-chroma-learn"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "chromadb>=1.0.15",
    "langchain>=0.3.26",
    "langchain-chroma>=0.2.4",
    "langchain-community>=0.3.27",
    "langchain-huggingface>=0.3.0",
    "langchain-openai>=0.3.27",
    "pytest>=8.4.1",
    "sentence-transformers>=5.0.0",
]

[dependency-groups]
dev = [
    "mypy>=1.16.1",
    "ruff>=0.12.2",
]

```

## 第零步，准备文档

在项目根目录下创建一个 docs 文件夹。将自己的 Markdown 文档放入该目录。我们将使用这些文档来构建知识库。

我将自己的 CMake 教程的大纲文档放入了 `docs` 目录下。

## 第一步，加载 `docs` 目录下的所有 Markdown 文档

我们将使用 `DirectoryLoader` 来加载 `docs` 目录下的所有 Markdown 文档。这个加载器会自动识别目录中的所有 Markdown 文件，并将其内容读取为文档对象。

```python
from langchain_community.document_loaders import (
    DirectoryLoader,
    TextLoader,
)

# --- 1. 加载 `docs` 目录下的所有 Markdown 文档 ---
loader = DirectoryLoader(
    "./docs",
    glob="**/*.md",
    loader_cls=TextLoader,
    loader_kwargs={"encoding": "utf-8"},
    show_progress=True,
)
documents = loader.load()
print(f"成功加载 {len(documents)} 个原始文档。")
```

## 第二步，分割文档

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
chunks = text_splitter.split_documents(documents)
print(f"文档被分割成 {len(chunks)} 个块。")
```

为什么需要分割文档？两个原因：

1. 上下文窗口限制：大模型一次能处理的文本长度是有限的（即“上下文窗口”）。过长的文本会被截断。
2. 检索精度：为了精确回答问题，我们希望只将与问题最相关的“段落”提供给模型，而不是无关信息占多数的整篇文档。

这几乎是所有 RAG 应用的通用做法，如果不理解这个步骤，后续的检索和生成步骤可能会让你感到困惑。

## 第三步，初始化 Embedding 和创建 VectorStore

我们将使用 HuggingFaceEmbeddings 来初始化文本块的嵌入表示，并将其存储在 ChromaDB 中。

```python
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-small-zh-v1.5")
vectorstore = Chroma.from_documents(
    documents=chunks,  # 注意：这里传入的是分割后的 chunks
    embedding=embeddings,
    persist_directory="./chroma_db_from_md",  # 使用一个新的目录
)

```

`HuggingFaceEmbeddings` 是对 Hugging Face 模型的封装，它会将文本转换为向量表示，这里面的模块可以自定义，嵌入模型的性能上限，通常也是 RAG 应用的性能瓶颈之一，我这里使用了 `BAAI/bge-small-zh-v1.5` 模型，它是一个中文的嵌入模型，适合处理中文文本。

`Chroma.from_documents` 方法会将这些向量存储在 ChromaDB 中，并持久化到指定目录(`./chroma_db_from_md`)，可以类比为我们从书本中记笔记，将重要信息提取并存储起来，以便后续查阅，下次就不用从课本中重新查找了，直接从笔记中检索即可。

## 第四步，构建链

```python
retriever = vectorstore.as_retriever(search_kwargs={"k": 7})  # 增大返回块数
llm = ChatOpenAI(
    model_name="deepseek/deepseek-chat-v3-0324:free",
    temperature=0.0,
    base_url="https://openrouter.ai/api/v1",
    api_key="sk-*", # 替换为你的 OpenRouter API Key
)

template = """
请根据以下上下文，列出所有未完成（[ ]）的章节标题和编号，不要遗漏。
上下文:
{context}

问题: {question}
"""

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一个专业的文档分析助手，查看分析文档。"),
    ("human", template),
    ("placeholder", "{agent_scratchpad}"),
])


def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)


rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

# --- 5. 进行问答 ---
query = "我的 cmake 大纲中，有什么没有完成的部分?"
result = rag_chain.invoke(query)
print("回答:", result)

```

在这个步骤中，我们将构建一个 LangChain 链，它将负责处理用户的查询并返回答案，当我们使用 `rag_chain.invoke(query)` 时，链会自动执行以下步骤：

1. 使用 `retriever` 从 ChromaDB 中检索与查询相关的文本块。
2. 将检索到的文档块格式化为字符串，以便后续处理。
3. 使用 LLM（在这里是 DeepSeek Chat 模型）生成回答。
4. 将 LLM 的输出解析为字符串格式。

实际开发中，通常开发到 `rag_chain` 这个阶段，后续的问答逻辑会被封装成一个 API 接口，供前端调用。

## 最终代码

```python
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain_community.document_loaders import (
    DirectoryLoader,
    TextLoader,
)

# 导入文本分割器
from langchain.text_splitter import RecursiveCharacterTextSplitter

# --- 1. 加载 `docs` 目录下的所有 Markdown 文档 ---
loader = DirectoryLoader(
    "./docs",
    glob="**/*.md",
    loader_cls=TextLoader,
    loader_kwargs={"encoding": "utf-8"},
    show_progress=True,
)
documents = loader.load()
print(f"成功加载 {len(documents)} 个原始文档。")

# --- 2. 分割文档 ---
# 为什么需要分割？
# a. 提升检索精度：只检索与问题最相关的文本块，而不是整个长文档。
# b. 适应模型上下文窗口：避免单次传入的上下文过长。
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
chunks = text_splitter.split_documents(documents)
print(f"文档被分割成 {len(chunks)} 个块。")

# --- 3. 初始化 Embedding 和创建 VectorStore ---
# 这一步会将所有文本块转换成向量并存入 ChromaDB
embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-small-zh-v1.5")
vectorstore = Chroma.from_documents(
    documents=chunks,  # 注意：这里传入的是分割后的 chunks
    embedding=embeddings,
    persist_directory="./chroma_db_from_md",  # 使用一个新的目录
)
print("向量数据库创建并持久化成功！")


# --- 4. 构建 langchain 链---
retriever = vectorstore.as_retriever(search_kwargs={"k": 7})  # 增大返回块数
llm = ChatOpenAI(
    model_name="deepseek/deepseek-chat-v3-0324:free",
    temperature=0.0,
    base_url="https://openrouter.ai/api/v1",
    api_key="sk-*", # 替换为你的 OpenRouter API Key
)

template = """
请根据以下上下文，列出所有未完成（[ ]）的章节标题和编号，不要遗漏。
上下文:
{context}

问题: {question}
"""

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一个专业的文档分析助手，查看分析文档。"),
    ("human", template),
    ("placeholder", "{agent_scratchpad}"),
])


def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)


rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

# --- 5. 进行问答 ---
query = "我的 cmake 大纲中，有什么没有完成的部分?"
result = rag_chain.invoke(query)
print("回答:", result)

```
