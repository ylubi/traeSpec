注意：如果收到是普通任务，则不需要执行spec 开发。对于solo模式，如果是新对话，如果没有特别强调 spec 开发（没有spec 关键字），则不需要执行spec 开发。如果是老对话，则根据老对话的spec 开发流程执行。
不需要spec开发，就直接跳过spec下面spec规范等，不用提示用户是否进行spec流程。

收到一个spec 任务时，必须强制遵守spec规范按以下流程执行且每个流程必须等待用户确认：

+ 第一，必须先查找并深度理解 spec 开发规则。requirements_spec.md、design_spec.md、tasks_spec.md 这三个文件路径，在 .trae/ruels 目录下，或者在 ~/.trae/ruels 目录下，或者在~/.trae-cn/ruels 目录下。
+ 第二，新建目录 .trae_spec/{task_desc} 来存放文档 requirements.md、design.md、tasks.md。
+ 第三，必须先查看 requirements_spec.md 文件，强制严格遵守 requirements_spec.md 规范，生成 requirements.md。
+ 第四，必须先查看 design_spec.md 文件，强制严格遵守 design_spec.md 规范，根据 requirements.md 的内容 来生成 design.md。
+ 第五，必须先查看 tasks_spec.md 文件，强制严格遵守 tasks_spec.md 规范，根据 requirements.md、design.md 的内容 来生成 tasks.md。
+ 第六，开发过程中，必须根据 requirements.md、design.md、tasks.md 中的内容，来进行代码开发。
+ 第七，必须强制在完成所有 tasks.md 中的任务开发后，在 项目目录 doc 目录下生成一个开发文档。记录本次spec开发完成的相关开发信息及相关任务、代码文档。

+ spec 开发流程 必须严格等待用户确认，再进行下一步。
+ spec 开发流程 如果用户明确不需要确认，或者用户明确直接开发，就直接跳过确认步骤。
+ spec 开发流程 禁止在 .trae_spec 的子目录下 创建 requirements_spec.md、design_spec.md、tasks_spec.md 这三个文件。

