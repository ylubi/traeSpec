注意：如果收到是普通任务，则不需要执行spec 开发。
收到一个spec 任务时，必须按以下流程执行：

+ 第一，必须根据 requirements_spec.md 中的规范，来生成 requirements.md。下一个步骤前必须有用户确认。
+ 第二，必须根据 design_spec.md 中的规范，根据 requirements.md 的内容 来生成 design.md。下一个步骤前必须有用户确认。
+ 第三，必须根据 tasks_spec.md 中的规范，根据 requirements.md、design.md 的内容 来生成 tasks.md。下一个步骤前必须有用户确认。

+ .trae_spec 目录中的每个子目录下，只有 requirements.md、design.md、tasks.md 这三个文件，不存在 requirements_spec.md、design_spec.md、tasks_spec.md 这三个文件。

# spec 开发规范

## spec 开发 生成流程注意事项

+ 新建目录 .trae_spec/ 来存放 spec 文档
+ 每次spec 任务，必须先创建一个子目录，子目录名称采用 kebab-case 格式
+ requirements.md 只是进行需求分析，不需要进行详细的设计。
+ 生成 requirements.md 后，必须通过用户确认后，才能生成 design.md。design.md 是对需求的详细设计，不需要进行任务拆解。
+ 生成 design.md 后，必须通过用户确认后，才能生成 tasks.md。
+ 生成 tasks.md 后，必须通过用户确认后，才能生成代码。
+ 严格遵循 requirements_spec.md、design_spec.md、tasks_spec.md 中的规范。

## spec 开发 任务管理注意事项

+ 严格根据 tasks.md 中的任务顺序，依次完成项目。并严格管理 tasks.md 中的任务状态。
+ 注意管理好任务状态。开始任务前，必须先修改 tasks.md 中的相应任务状态为进行中。任务完成后，必须修改 tasks.md 中的相应任务状态为已完成。
+ 任务异常时，必须修改 tasks.md 中的相应任务状态为任务异常。

## 项目开发必须严格遵循事项

+ 严格遵循 requirements_spec.md、design_spec.md、tasks_spec.md 中的规范
+ 每个流程必须有用户确认过程。
+ 开始tasks.md 中的任务前，必须先修改 tasks.md 中的相应任务状态为进行中。任务完成后，必须修改 tasks.md 中的相应任务状态为已完成。每次只修改一个任务的状态。任务默认状态为空。
+ 这里的任务，是特定值 tasks.md 文件中的任务。
