---
title: "Repository and Unit of work pattern in ASP.net core 3.1"
date: "2020-07-30"
categories: 
  - "architecture"
  - "patterns"
tags: 
  - "repository"
  - "transactions"
  - "unitofwork"
  - "uow"
---

### Source Code

If you wish to follow along with the code used in this post, you can find it [on GitHub here](https://github.com/PradeepLoganathan/Repository-UOW-Sample).

### Repository Pattern

A Repository is used to manage aggregate persistence and retrieval. The repository mediates between the data-access layer and the domain. It decouples the domain layer from the data layer effectively. It does so by providing collection-like access to the underlying data. The repository offers a collection interface by providing methods to add, modify, remove, and fetch domain objects. This enables the domain to remain agnostic of the underlying persistence mechanism. This allows both these layers to evolve independently maintaining high cohesion with low coupling.

![](images/Repository-Pattern-Pradeep-Loganathan-1024x556.png)

Applying Repository Pattern to Domain design

### Pros

The repository pattern abstracts the underlying technology and architecture of the persistence layer. Even though this abstraction is highly desirable, reality is that the choice of the persistence technology does influence the rest of the stack in some ways. Typically, each repository is responsible for persisting an aggregate root.

The repository pattern makes data retrieval explicit by using named query methods and limiting access to the aggregate level. It does not offer an open interface into the data model. This makes it easy to express the intent of the operation explicit in terms of the domain model. It also makes it easy to tune the queries as they are contained to the repository alone. Using the Specification pattern makes authoring named queries explicit and highly maintainable.

Implementing the Repository pattern breaks the repository layer into smaller units of easily testable code. Since the domain layer depends on the repository interface rather than the concrete implementation, it makes unit testing easier by injecting mock repositories during testing.

### Is it an Antipattern?

Some folks consider the repository pattern as an antipattern as it abstracts away the underlying persistence technology. The argument is that this abstraction does not enable the other layers to make use of the power of the persistence technology. This may be true in cases where the codebase is small. However, as the complexity of the code base increases the benefits of the repository kicks in to reduce coupling and increase cohesion. This makes the code more maintainable and testable. It also prevents the infrastructure concerns from leaking into the domain allowing it to be purely concerned with business rules.

### Implementing Repository pattern

Let us now jump into code to setup a sample API which uses the repository pattern to persist domain aggregates. The code for this post is [here on GitHub](https://github.com/PradeepLoganathan/Repository-UOW-Sample). I am creating a sample Bookstore API which is used to manage books and book catalogues. The solution has an API project and two library projects implementing the domain and the repository layer as below. The API project is responsible for REST concerns, the domain project represents the domain layer with the necessary business logic and the Repository layer represents the persistence aspects. To keep things simple the domain layer contains two aggregates (Books and Catalogue) with an entity each. The solution is setup as below

![](images/Solution-Setup.png)

Solution structure

The BookStore.Domain project represents the domain layer. I am keeping it quite simple as described above.

<script src="https://gist.github.com/PradeepLoganathan/ebf98130de9174a58cdf51b67fbea234.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/ebf98130de9174a58cdf51b67fbea234">View this gist on GitHub</a>

Book Aggregate Root

<script src="https://gist.github.com/PradeepLoganathan/cc31d3c285dbba33d24a4ec405e2e8fa.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/cc31d3c285dbba33d24a4ec405e2e8fa">View this gist on GitHub</a>

Catalogue Aggregate Root

#### Repository Interfaces

The above two entities represent a book and a catalogue domain object. The catalogue entity represents a collection of books that form a catalogue. The catalogue & the book entities also represent an aggregate root within this bounded context. Each aggregate root has its own repository interface IBooksRepository and ICatalogueRepository which it uses to save and retrieve its persistent state from the database. I prefer to create the Repository interfaces in the same location as the aggregate roots as it reinforces the boundary that the aggregate root implies. The initial design of the repository interfaces is below

<script src="https://gist.github.com/PradeepLoganathan/0b46fe439e3d0c367838aa7054cfb15d.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/0b46fe439e3d0c367838aa7054cfb15d">View this gist on GitHub</a>

IBooksRepository

<script src="https://gist.github.com/PradeepLoganathan/8d4892e9dcc808dbee1a7affe464b35a.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/8d4892e9dcc808dbee1a7affe464b35a">View this gist on GitHub</a>

ICatalogueRepository

As you can see both the repository interfaces are exactly similar except for the entity type that they manage. We can refactor these interfaces to use a generic repository interface as below.

#### Generic Repository interface

The refactored interface representing a generic repository is as below.

<script src="https://gist.github.com/PradeepLoganathan/9ff9a3fd01b65fb86e0592d68b9b9dc6.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/9ff9a3fd01b65fb86e0592d68b9b9dc6">View this gist on GitHub</a>

Generic Repository interface

Now the other two Repository interfaces can be refactored to use the generic repository interface as below

<script src="https://gist.github.com/PradeepLoganathan/04170fc4b45893cc36cdba3ccf203f54.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/04170fc4b45893cc36cdba3ccf203f54">View this gist on GitHub</a>

Books repository Interface

<script src="https://gist.github.com/PradeepLoganathan/99a8ea6f62dfc720723ed47071398a94.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/99a8ea6f62dfc720723ed47071398a94">View this gist on GitHub</a>

Catalogue repository interface

#### Concrete Repository classes

The repository layer implements the interfaces defined in each aggregate root. This allows the repository implementation to be abstracted away from the domain layer. The domain layer only deals with the abstract repositories and does not concern itself with the concrete implementation of the repository. The concrete implementation of the repository can switch between any persistence layer without impacting the domain as the interface guarantees consistency. The Repository instance uses EFCore to connect to a SQL Server instance and perform database actions. To use EFCore we need to install the below nuget packages into the BookStore.Repository project.

```
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

Before we can create our Concrete repository classes we need to implement a DbContext class to connect to the database. The DbContext implementation is a representation of a session between the repository and the database. It is used to query and save instances of the entities into our data source. It also provides additional functionality such as transaction control, change tracking etc.

<script src="https://gist.github.com/PradeepLoganathan/25ca3b3f3beb1278f0cbbe0ba725d593.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/25ca3b3f3beb1278f0cbbe0ba725d593">View this gist on GitHub</a>

BookStoreDbContext class

Now that we have the DbContext class representing a connection to the database we can create the necessary concrete implementations of the Repository used by the two aggregate root entities Books and Catalogue. The concrete repository classes are below

<script src="https://gist.github.com/PradeepLoganathan/b053a879115cdc0c042eff1f1a6d7e51.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/b053a879115cdc0c042eff1f1a6d7e51">View this gist on GitHub</a>

Repository implementation

#### Generic Concrete Repository implementation

The Repository class for Books is also exactly similar to the catalogue repository class. We can refactor them to create a generic implementation of a concrete repository class. This generic implementation can be an abstract class and will have methods needed to perform all CRUD operations on the underlying set. The Generic repository class is below.

<script src="https://gist.github.com/PradeepLoganathan/e0b9f61c2ceb3392ee5fcf855990cfe5.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/e0b9f61c2ceb3392ee5fcf855990cfe5">View this gist on GitHub</a>

Generic Repository implementation

The repository classes can now inherit from the generic abstract repository class and implement functionality which is specific to that entity. This is one of the best advantages of the repository pattern as we can now use named queries returning specific business data. The books repository is shown below post refactoring and adding the generic repository. We can also see the use of a name query method.

<script src="https://gist.github.com/PradeepLoganathan/a3b80f003b9fa6e1329f53bbaf172e92.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/a3b80f003b9fa6e1329f53bbaf172e92">View this gist on GitHub</a>

Books Repository

#### Generic Repository vs Specific Repository

There is a long-standing debate about the efficacy of a specific repository per aggregate root vs a generic repository. This debate is as old as the repository pattern itself. A repository is an essential part of the domain being modelled. This is the primary reason the repository interfaces for the entities are in the domain layer. Each entity is unique and has unique characteristics that impacts its persistence behavior. For e.g. Some entities cannot be deleted, some entities cannot be added, and not every entity needs a repository. Queries vary wildly and are specific to each entity. The repository API becomes as unique as the entity itself. However, it is easier to setup a generic repository initially and refactor it to be specific as the design and requirements evolve. I usually end up creating Specific repositories but abstracting away common operations into a generic abstract base repository with overridable methods.

#### Injecting Repository and DbContext

To use the BookStoreDBContext and the repositories we need to be able to inject them into the dependency injection container. We can do that by creating an extension method in the repository layer as below. (I am taking a shortcut by explicitly specifying the connection string rather than adding it to the settings file)

<script src="https://gist.github.com/PradeepLoganathan/e87a8b14ec396f19120cd4c7e83acd4f.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/e87a8b14ec396f19120cd4c7e83acd4f">View this gist on GitHub</a>

Injecting Repositories and DbContext

I can now add the call to AddRepository in the startup class of the API so that this method will be called on Startup. This pattern makes it much neater to add the necessary dependencies at the appropriate layer.

<script src="https://gist.github.com/PradeepLoganathan/4b3fba93df07e1af90ff681dba23aed1.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/4b3fba93df07e1af90ff681dba23aed1">View this gist on GitHub</a>

Now that we have the repositories and the context in place and the necessary services being injected , it is time to switch context to introduce the Unit of work pattern and tie it up with the repository pattern.

### Unit of Work

The unit of work pattern keeps track of all changes to aggregates. Once all updates of the aggregates in a scope are completed, the tracked changes are played onto the database in a transaction so that the database reflects the desired changes. Thus, the unit of work pattern tracks a business transaction and translates it into a database transaction, wherein steps are collectively run as a single unit. To ensure that data integrity is not compromised, the transaction commits or is rolled back discretely, thus preventing indeterminate state.

#### Unit of Work interface design

The unit of work interface for our sample is below

<script src="https://gist.github.com/PradeepLoganathan/2cfecde85abb40c867666f317b767ed7.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/2cfecde85abb40c867666f317b767ed7">View this gist on GitHub</a>

Unit of Work interface

#### Unit of Work concrete implementation

The concrete implementation of the Unit of Work interface is below

<script src="https://gist.github.com/PradeepLoganathan/bc34427801a16f6e479459658d0a0604.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/bc34427801a16f6e479459658d0a0604">View this gist on GitHub</a>

Concrete implementation of Unit of Work

The Unit of work ties up all the entities involved in a logical business process into a single transaction and either commits the transaction or rolls it back.

### Stringing it all together

Now we have implemented both the repository pattern and the Unit of work pattern with the appropriate abstractions and thier concrete implementations. We can now use this to both query and to perform transactional updates of the aggregate roots to the database. We have also wired up dependency injection to provide these services to the API layer. We can now inject the unit of work into our controllers where the magic finally happens.

In the below code, I am injecting the Unit of work interface into the Books controller. I am using the unit of work to retrieve the repository and use named queries in the get method of the controller. I am also using the interface to add a book and a corresponding catalog in a transaction in the post method. This will ensure that either the book and the catalog are written to the database or both are not written to the database.

<script src="https://gist.github.com/PradeepLoganathan/7e5c2dd63bc9b761df5dec175aeead7c.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/7e5c2dd63bc9b761df5dec175aeead7c">View this gist on GitHub</a>

Books Controller

### Firing up the API

With everything tied up, we can now run the project and fire up postman to submit a get request at the books endpoint. We can now operate the books resource at this end point.

![](images/Postman-Get.png)

Postman - Books API

The above sample project demonstrates how the Repository and the Unit of work pattern work together to ensure a clean design to hydrate and persist aggregate roots and entities to a database.

> Photo by [@canmandawe](https://unsplash.com/@canmandawe?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
