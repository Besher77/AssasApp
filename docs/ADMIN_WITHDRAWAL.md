# طلبات سحب رصيد المهندس (للإدارة)



عند طلب المهندس سحباً من المحفظة:



1. يُخصم المبلغ من رصيد محفظته فوراً (بعد التحقق: **آيبان معتمد** من الإدارة، ومبلغ **أكبر من 100** ر.س) ويُنشأ مستند في **`withdrawal_requests`** بحالة **`pending`**.

2. يُربط بمعاملة في **`transactions`** (نوع `withdraw`) بحالة **`pending`**.



## حقول `withdrawal_requests`



| الحقل | الوصف |

|--------|--------|

| `userId` | المهندس |

| `amount` | المبلغ بالريال |

| `status` | `pending` → ثم **`transferred`** أو **`rejected`** |

| `adminMessage` | سبب عدم التحويل (عند الرفض) |

| `linkedTransactionId` | معرف المعاملة المرتبطة |

| `bankAccount` | ملاحظة اختيارية من المهندس |

| `refundApplied` | يُضبط تلقائياً `true` عند الرفض (Cloud Function) |

| `refundedAt` | وقت إرجاع الرصيد |



## إجراءات الإدارة (Console / Admin SDK)



### عند إتمام التحويل البنكي

1. حدّث `withdrawal_requests/{id}`: `status` = **`transferred`**

2. حدّث `transactions/{linkedTransactionId}`: `status` = **`completed`**, وأضف `completedAt`



### عند الرفض (من حالة `pending` فقط)

1. حدّث `withdrawal_requests/{id}`: `status` = **`rejected`** و`adminMessage` = السبب (اختياري).

2. **Cloud Function `refundWithdrawalOnReject`** تعيد المبلغ تلقائياً إلى **`wallets/{userId}`**، وتُلغي المعاملة المرتبطة (`cancelled`)، وتضيف **`refundApplied`** و**`refundedAt`**، وتُنشئ إشعاراً + **FCM** للمهندس.



> لا تعيد يدوياً زيادة الرصيد عند الرفض من `pending` — الدالة تتكفل بذلك.  

> إذا كان الطلب **`transferred`** ثم رُفض لاحقاً، لا تعيد الدالة السحب تلقائياً (يجب المعالجة يدوياً إن لزم).



**ملاحظة:** قواعد الأمان تمنع المهندس من تعديل `withdrawal_requests` بعد الإنشاء.



**النشر:** `firebase deploy --only functions` بعد تفعيل `refundWithdrawalOnReject`.


